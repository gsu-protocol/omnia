#!/bin/bash
test_path=$(cd "${BASH_SOURCE[0]%/*}"; pwd)
root_path=$(cd "$test_path/../.."; pwd)
lib_path="$root_path/lib"

. "$lib_path/log.sh"
. "$lib_path/util.sh"
. "$lib_path/config.sh"

. "$root_path/lib/tap.sh" 2>/dev/null || . "$root_path/test/tap.sh"

_validConfig="$(jq -c . "$test_path/configs/oracle-relayer-test.conf")"

# Setting up clean vars
ETH_GAS_SOURCE=""
ETH_MAXPRICE_MULTIPLIER=""
ETH_TIP_MULTIPLIER=""
ETH_GAS_PRIORITY=""

# Testing default values
_json=$(jq -c '.ethereum' <<< "$_validConfig")
assert "importGasPrice should correctly parse values" run importGasPrice $_json

assert "ETH_GAS_SOURCE should have value: ethgasstation" match "^node" <<<$ETH_GAS_SOURCE
assert "ETH_MAXPRICE_MULTIPLIER should have value: 1" match "^1$" <<<$ETH_MAXPRICE_MULTIPLIER
assert "ETH_TIP_MULTIPLIER should have value: 1" match "^1$" <<<$ETH_TIP_MULTIPLIER
assert "ETH_GAS_PRIORITY should have value: slow" match "^fast" <<<$ETH_GAS_PRIORITY

# Testing changed values
_json="{\"gasPrice\":{\"source\":\"ethgasstation\",\"maxPriceMultiplier\":0.5,\"tipMultiplier\":1.0,\"priority\":\"slow\"}}"
assert "importGasPrice should correctly parse new values" run importGasPrice $_json

assert "ETH_GAS_SOURCE should have value: ethgasstation" match "^ethgasstation$" <<<$ETH_GAS_SOURCE
assert "ETH_MAXPRICE_MULTIPLIER should have value: 0.5" match "^0.5$" <<<$ETH_MAXPRICE_MULTIPLIER
assert "ETH_TIP_MULTIPLIER should have value: 1" match "^1$" <<<$ETH_TIP_MULTIPLIER
assert "ETH_GAS_PRIORITY should have value: slow" match "^slow$" <<<$ETH_GAS_PRIORITY

# Testing Infura keys
_network_json='{"network":"http://geth.local:8545","infuraKey":"wrong-key"}'
assert "infuraKey should fail if incorrect key configured" fail importNetwork $_network_json
