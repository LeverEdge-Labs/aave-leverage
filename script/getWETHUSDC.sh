export ALICE=0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266
export WETH_ETH=0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
export LUCKY_USER_WETH=0xc1C736F2Ac0e0019A188982c7c8C063976A4d8d9

USDC_ETH=0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
export LUCKY_USER_USDC=0x203520F4ec42Ea39b03F62B20e20Cf17DB5fdfA7

cast call $WETH_ETH \
  "balanceOf(address)(uint256)" \
  $LUCKY_USER_WETH

cast rpc anvil_impersonateAccount $LUCKY_USER_WETH
cast send $WETH_ETH \
--from $LUCKY_USER_WETH \
  "transfer(address,uint256)(bool)" \
  $ALICE \
  100000000000000000000

cast rpc anvil_impersonateAccount $LUCKY_USER_USDC
cast send $USDC_ETH \
--from $LUCKY_USER_USDC \
  "transfer(address,uint256)(bool)" \
  $ALICE \
  1000000000000

