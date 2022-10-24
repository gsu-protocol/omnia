pullOracleTime () {
	local _assetPair="$1"
	local _address
	_address=$(getOracleContract "$_assetPair")
	if ! [[ "$_address" =~ ^(0x){1}[0-9a-fA-F]{40}$ ]]; then
		error "Error - Invalid Oracle contract"
		return 1
	fi

	timeout -s9 10 ethereum call "$_address" "age()(uint32)" --rpc-url "$ETH_RPC_URL"
}

pullOracleQuorum () {
	local _assetPair="$1"
	local _address
	_address=$(getOracleContract "$_assetPair")
	if ! [[ "$_address" =~ ^(0x){1}[0-9a-fA-F]{40}$ ]]; then
		error "Error - Invalid Oracle contract"
		return 1
	fi

	timeout -s9 10 ethereum call "$_address" "bar()(uint256)" --rpc-url "$ETH_RPC_URL"
}

pullOraclePrice () {
	local _assetPair="$1"
	local _address
	local _rawStorage
	_address=$(getOracleContract "$_assetPair")
	if ! [[ "$_address" =~ ^(0x){1}[0-9a-fA-F]{40}$ ]]; then
			error "Error - Invalid Oracle contract"
			return 1
	fi

	_rawStorage=$(timeout -s9 10 ethereum storage "$_address" 0x1 --rpc-url "$ETH_RPC_URL")

	[[ "${#_rawStorage}" -ne 66 ]] && error "oracle contract storage query failed" && return

	ethereum --from-wei "$(ethereum --to-dec "${_rawStorage:34:32}")"
}

pushOraclePrice () {
		local _assetPair="$1"
		local _oracleContract
		
		# Using custom gas pricing strategy
		local _fees
		_fees=($(getGasPrice))

		_oracleContract=$(getOracleContract "$_assetPair")
		if ! [[ "$_oracleContract" =~ ^(0x){1}[0-9a-fA-F]{40}$ ]]; then
		  error "Error - Invalid Oracle contract"
		  return 1
		fi

		local _gasParams
		_gasParams=(--rpc-url "$ETH_RPC_URL" --gas-price "${_fees[0]}")
		[[ $ETH_TX_TYPE -eq 2 ]] && _gasParams+=(--prio-fee "${_fees[1]}")
		_gasParams+=(--gas "$ETH_GAS")

		log "Sending tx..."
		tx=$(ethereum --rpc-url "$ETH_RPC_URL" \
				send --async "$_oracleContract" 'poke(uint256[] memory,uint256[] memory,uint8[] memory,bytes32[] memory,bytes32[] memory)' \
				"[$(join "${allPrices[@]}")]" \
				"[$(join "${allTimes[@]}")]" \
				"[$(join "${allV[@]}")]" \
				"[$(join "${allR[@]}")]" \
				"[$(join "${allS[@]}")]")
		
		_status="$(timeout -s9 60 ethereum receipt "$tx" status --rpc-url "$ETH_RPC_URL" )"
		_gasUsed="$(timeout -s9 60 ethereum receipt "$tx" gasUsed --rpc-url "$ETH_RPC_URL" )"
		
		# Monitoring node helper JSON
		verbose "Transaction receipt" "tx=$tx" "type=$ETH_TX_TYPE" "maxGasPrice=${_fees[0]}" "prioFee=${_fees[1]}" "gasUsed=$_gasUsed" "status=$_status"
}
