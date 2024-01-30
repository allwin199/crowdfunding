-include .env

.PHONY: deployToAnvil deployToPolygonMumbai
# .phoney describes all the command are not directories

# Including @ will not display the acutal command in terminal
# The backslash (\) is used as a line continuation 

deployToAnvil:
	@forge script script/DeployCrowdFunding.s.sol:DeployCrowdFunding --rpc-url $(ANVIL_RPC_URL) --account $(ACCOUNT_FOR_ANVIL) --sender $(ANVIL_KEYCHAIN) --broadcast

deployToPolygonMumbai:
	@forge script script/DeployCrowdFunding.s.sol:DeployCrowdFunding --rpc-url $(SEPOLIA_RPC_URL) --account $(ACCOUNT_FOR_POLYGON_MUMBAI) --sender $(POLYGIN_MUMBAI_KEYCHAIN) --broadcast --verify $(POLYSCAN_API_KEY)
