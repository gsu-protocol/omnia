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

# Testing importNetwork() & Infura keys

# Mocking ETH-RPC request
getLatestBlock () {
  printf "1"
}
export -f getLatestBlock

_network_json='{"network":"http://geth.local:8545","infuraKey":"wrong-key"}'

errors=()
assert "importNetwork: infuraKey should fail if incorrect key configured" fail importNetwork $_network_json

errors=()
assert "importNetwork: infuraKey should give valid error message" match "Error - Invalid Infura Key" < <(capture importNetwork $_network_json)

# NOTE: We have to reset `errors` after failed run
errors=()
_network_json='{"network":"http://geth.local:8545"}'
assert "importNetwork: missing infuraKey should pass validation" run importNetwork $_network_json

_network_json='{"network":"http://geth.local:8545","infuraKey":""}'
assert "importNetwork: empty infuraKey should pass validation" run importNetwork $_network_json

INFURA_KEY=""
_network_json='{"network":"http://geth.local:8545","infuraKey":"305ac4ca797b6fa19d5e985b8269f6c5"}'\

assert "importNetwork: valid infuraKey should pass validation" run importNetwork $_network_json
assert "importNetwork: valid infuraKey should be set as ENV var" match "^305ac4ca797b6fa19d5e985b8269f6c5$" <<<$INFURA_KEY

assert "importNetwork: custom network should be set correctly" run importNetwork $_network_json
assert "importNetwork: custom network value should be set to ENV var ETH_RPC_URL" match "^http://geth.local:8545$" <<<$ETH_RPC_URL

assert "importNetwork: ethlive netork shouldn't crash" run importNetwork '{"network":"ethlive"}'
assert "importNetwork: ethlive network should expand to full url" match "^https://mainnet.infura.io" <<<$ETH_RPC_URL

assert "importNetwork: mainnet netork shouldn't crash" run importNetwork '{"network":"mainnet"}'
assert "importNetwork: mainnet network should expand to full url" match "^https://mainnet.infura.io" <<<$ETH_RPC_URL

assert "importNetwork: ropsten netork shouldn't crash" run importNetwork '{"network":"ropsten"}'
assert "importNetwork: ropsten network should expand to full url" match "^https://ropsten.infura.io" <<<$ETH_RPC_URL

assert "importNetwork: kovan netork shouldn't crash" run importNetwork '{"network":"kovan"}'
assert "importNetwork: kovan network should expand to full url" match "^https://kovan.infura.io" <<<$ETH_RPC_URL

assert "importNetwork: rinkeby netork shouldn't crash" run importNetwork '{"network":"rinkeby"}'
assert "importNetwork: rinkeby network should expand to full url" match "^https://rinkeby.infura.io" <<<$ETH_RPC_URL

assert "importNetwork: goerli netork shouldn't crash" run importNetwork '{"network":"goerli"}'
assert "importNetwork: goerli network should expand to full url" match "^https://goerli.infura.io" <<<$ETH_RPC_URL

getLatestBlock () {
  printf "some error message"
}
export -f getLatestBlock
assert "importNetwork: invalid block number should fail execution" fail importNetwork '{"network":"goerli"}'

getLatestBlock () {
  printf ""
}
export -f getLatestBlock
assert "importNetwork: empty block number should fail execution" fail importNetwork '{"network":"goerli"}'

