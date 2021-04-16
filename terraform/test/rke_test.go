package terratest

import (
	"fmt"
	"strings"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

const (
	DEFAULTAMOUNTOFWORKERVMS = 2
	DEFAULTAMOUNTOFMASTERVMS = 3
)

func getDefaultrkeVariables(rkeClusterName string) map[string]interface{} {
	defaults := map[string]interface{}{
		"amount_of_rke_worker_vms": DEFAULTAMOUNTOFWORKERVMS,
		"rke_cluster_name":         rkeClusterName,
	}
	return defaults
}

func getrkeTerraformOptions(t *testing.T, vars map[string]interface{}, targets []string) *terraform.Options {
	return terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../",
		NoColor:      true,
		Vars:         vars,
		EnvVars: map[string]string{
			"TF_LOG":      "trace",
			"TF_LOG_PATH": "tf.log",
		},
		Targets: targets,
	})
}

func createrkeCluster(t *testing.T, terraformOptions *terraform.Options, expectError bool) error {
	if expectError {
		_, err := terraform.InitAndApplyE(t, terraformOptions)
		return err
	}
	terraform.InitAndApply(t, terraformOptions)
	return nil
}

func TestTerraform_RKE_CreateCluster(t *testing.T) {
	rkeClusterName := fmt.Sprintf("terratest-rke-%d", generateRandomNumber())
	vars := getDefaultrkeVariables(rkeClusterName)
	terraformOptions := getrkeTerraformOptions(t, vars, getEmptyTargets())
	defer terraform.Destroy(t, terraformOptions)
	createrkeCluster(t, terraformOptions, false)
	basicClusterTestHelper(t, terraformOptions, 0, 0, 0)
}

func TestTerraform_RKE_CreateClusterMultipleWorkerNodes(t *testing.T) {
	rkeClusterName := fmt.Sprintf("terratest-rke-%d", generateRandomNumber())
	vars := getDefaultrkeVariables(rkeClusterName)
	vars["amount_of_rke_worker_vms"] = 4
	terraformOptions := getrkeTerraformOptions(t, vars, getEmptyTargets())
	defer terraform.Destroy(t, terraformOptions)
	createrkeCluster(t, terraformOptions, false)
	basicClusterTestHelper(t, terraformOptions, 0, 0, 0)
}

func TestTerraform_RKE_ClusterScaling(t *testing.T) {
	rkeClusterName := fmt.Sprintf("terratest-rke-%d", generateRandomNumber())
	vars := getDefaultrkeVariables(rkeClusterName)
	terraformOptions := getrkeTerraformOptions(t, vars, getEmptyTargets())
	defer terraform.Destroy(t, terraformOptions)
	createrkeCluster(t, terraformOptions, false)
	basicClusterTestHelper(t, terraformOptions, 0, 0, 0)
	k8sOptions := k8s.NewKubectlOptions("", getKubeconfigPath(terraformOptions, rkeClusterName), "kube-system")
	clusterScalingTestHelper(t, k8sOptions, terraformOptions, 4, DEFAULTAMOUNTOFMASTERVMS, 4, 0, 2)
	clusterScalingTestHelper(t, k8sOptions, terraformOptions, 1, DEFAULTAMOUNTOFMASTERVMS, 2, 0, 5)
}

func clusterScalingTestHelper(t *testing.T, k8sOptions *k8s.KubectlOptions, terraformOptions *terraform.Options, amountOfWorkers, amountOfMasters, add, change, destroy int) {
	terraformOptions.Vars["amount_of_rke_worker_vms"] = amountOfWorkers
	assertPlanResult(t, terraformOptions, add, change, destroy)
	terraform.InitAndApply(t, terraformOptions)
	checkAmountOfNodes(t, k8sOptions, terraformOptions.Vars["amount_of_rke_worker_vms"].(int), amountOfMasters)
	hasCSIPods(t, k8sOptions)
}

func getPrivateKeyPath(clusterName string) string {
	return fmt.Sprintf("../rke_%s", clusterName)
}

func getKubeconfigPath(terraformOptions *terraform.Options, clusterName string) string {
	return fmt.Sprintf("%s/kube_config_cluster.yml", terraformOptions.TerraformDir)
}

func basicClusterTestHelper(t *testing.T, terraformOptions *terraform.Options, added, changed, deleted int) {
	assertPlanResult(t, terraformOptions, added, changed, deleted)
	amountOfWorkerNodes := terraformOptions.Vars["amount_of_rke_worker_vms"].(int)
	clusterName := terraformOptions.Vars["rke_cluster_name"].(string)
	k8sOptions := k8s.NewKubectlOptions("", getKubeconfigPath(terraformOptions, clusterName), "kube-system")
	checkAmountOfNodes(t, k8sOptions, amountOfWorkerNodes, DEFAULTAMOUNTOFMASTERVMS)
	hasCSIPods(t, k8sOptions)
	deployTestApplication(t, k8sOptions)
}

func checkAmountOfNodes(t *testing.T, k8sOptions *k8s.KubectlOptions, expectedAmountOfWorkerNodes int, amountOfMasters int) {
	currentNodes := k8s.GetNodes(t, k8sOptions)
	totalAmountOfNodes := expectedAmountOfWorkerNodes + amountOfMasters
	currentAmountOfNodes := len(currentNodes)
	assert.Equal(t, totalAmountOfNodes, currentAmountOfNodes, fmt.Sprintf("expected the amount of nodes to be %d but was %d", totalAmountOfNodes, currentAmountOfNodes))
}

func hasCSIPods(t *testing.T, k8sOptions *k8s.KubectlOptions) {
	csiProvisionerName := "csi-provisioner-ntnx-plugin"
	csiProvisionerExists := podExists(t, k8sOptions, csiProvisionerName)
	assert.True(t, csiProvisionerExists, fmt.Sprintf("csi pods containing name %s not found", csiProvisionerName))
	csiNodeName := "csi-node-ntnx-plugin"
	csiNodeExists := podExists(t, k8sOptions, csiNodeName)
	assert.True(t, csiNodeExists, fmt.Sprintf("csi pods containing name %s not found", csiNodeName))
}

func podExists(t *testing.T, k8sOptions *k8s.KubectlOptions, podName string) bool {
	listOption := metav1.ListOptions{}
	pods := k8s.ListPods(t, k8sOptions, listOption)

	found := false
	for _, p := range pods {
		found = strings.Contains(p.ObjectMeta.Name, podName)
		if found {
			break
		}
	}
	return found
}

func deployTestApplication(t *testing.T, k8sOptions *k8s.KubectlOptions) {
	kubeResourcePath := "./wordpress.yml"
	defer k8s.KubectlDelete(t, k8sOptions, kubeResourcePath)
	k8s.KubectlApply(t, k8sOptions, kubeResourcePath)
	checkPVC(t, k8sOptions)
}

func checkPVC(t *testing.T, k8sOptions *k8s.KubectlOptions) {
	latestPvcOutput := ""
	var err error
	maxRetries := 10
	currentRetry := 0
	allBound := false
	for currentRetry < maxRetries {
		latestPvcOutput, err = k8s.RunKubectlAndGetOutputE(t, k8sOptions, "get", "pvc")
		if err != nil {
			t.Fatalf("error occurred getting PVCs: %s", err)
		}
		allBound = areAllPVCsBound(latestPvcOutput)
		if allBound {
			break
		}
		currentRetry++
		time.Sleep(time.Second * 5)
	}
	if allBound == false {
		t.Fatalf("Not all PVCs were bound in time:\n %s", latestPvcOutput)
	}
	print("All PVCs bound!")
}

func areAllPVCsBound(pvcInputRaw string) bool {
	pvcInput := replaceDoubleSpaces(pvcInputRaw)
	inSplit := strings.Split(pvcInput, "\n")
	allBound := true
	for _, s := range inSplit {
		sSplit := strings.Split(s, " ")
		if sSplit[0] == "NAME" && sSplit[1] == "STATUS" && sSplit[2] == "VOLUME" {
			continue
		}
		if sSplit[1] != "Bound" {
			allBound = false
		}
	}
	return allBound
}
