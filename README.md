
# Algorithmic On-Chain Leverage Trading


### **What is this repository?**

The goal of this repository is to make on-chain algorithmic leverage trading possible in a single transaction without an intermediary protocol. Leverage trading protocols already exist such as dYdX and GMX, however, these are order book based exchanges.

### **Who is this for?**

This repository is currently in development, however, this repository will be useful for developers seeking to integrate leveraged long/short functionality into their on-chain protocols or smart contracts. 

### **Why is this cool and necessary?** 

Leverage trading can be achieved by using the flash loan and lending functionality of existing on-chain lending platforms. The ability to short an asset on chain is necessary for building more complex trading strategies such as the replication of an option contract, or to replicate the inverse payoff of impermanent loss of a Uniswap V3 liquidity position.  

### **How does it work?:**

#### **Max Theoretical Leverage for a Long Trade Using Aave V3 (Non-eMode)**

On Aave V3, the max loan-to-collateral ratio is 0.8 or 4/5.

$$loanToCollateralRatio = \frac{4}{5}$$

In the leverage contract, the flash loan amount to execute the leveraged trade is defined as follows:

$$flashLoanAmount = baseCollateral * (leverage - 1)$$

Where *baseCollateral* is the amount of the asset X being supplied by the user, and *leverage* is the amount of leverage the user wishes to long or short the asset.

To execute the long or short trade we need the following to be true as we withdraw the flash loan amount in another asset Y from Aave and then swap asset Y on Uniswap back to the flash loan asset X in order to repay the flash loan.

$$\frac{flashLoanAmount}{flashLoanAmount + baseCollateral} < \frac{4}{5}$$

To find the max leverage amount, we can use the following equation and solve for leverage:

$$\frac{flashLoanAmount}{flashLoanAmount + baseCollateral} = \frac{4}{5}$$

  Substituting *flashLoanAmount* for *baseCollateral*  * *leverage*

$$\frac{baseCollateral * (leverage - 1)}{baseCollateral * leverage + baseCollateral}  = \frac{4}{5}$$

Solving for leverage:

$$leverage = 5$$

The max theoretical leverage for a long trade using the liquidity of Aave V3 is 5x. The reason for this is that the maximum ratio of the user’s initial liquidity, and the maximum a user can deposit to Aave using their initial liquidity plus the flashloan, and be able to return the flash loan is: 1:5. 

The max theoretical leverage for a short trade trade using the liquidity of Aave V3 is 4x. The reason for this is that the maximum ratio of the user’s initial liquidity, and the maximum a user can borrow from Aave using their initial liquidity plus the flashloan, and be able to return the flash loan is: 1:4.

*The formula above does not include the 0.09% fee for flash loans and interest payments from Aave V3, nor the 0.05% or 0.3% fee for swaps on Uniswap (depending on the pool used).*

Below is a python3 code snippet to further explain the maximum leverage for a long and short trade using the liquidity of Aave V3

```python
# Long Trade
baseCollateral = 1000
leverage = 5

flashLoanAmount = baseCollateral * (leverage - 1)
totalDeposit = baseCollateral + flashLoanAmount

loanToCollateralRatio = flashLoanAmount / totalDeposit
flashToBaseRatio = flashLoanAmount / baseCollateral

print("flash loan amount in contract:", flashLoanAmount) 
print("total deposit in Aave:", totalDeposit)

print("loan to collateral ratio (must be < 0.8):", loanToCollateralRatio) 
print("loan to base ratio:", flashToBaseRatio)
```

```python
# Short Trade
baseCollateral = 1000
leverage = 4

flashLoanAmount = baseCollateral * leverage
totalDeposit = baseCollateral + flashLoanAmount

loanToCollateralRatio = flashLoanAmount / totalDeposit
flashToBaseRatio = flashLoanAmount / baseCollateral

print("flash loan amount in contract:", flashLoanAmount) 
print("total deposit in Aave:", totalDeposit)

print("loan to collateral ratio (must be < 0.8):", loanToCollateralRatio) 
print("loan to base ratio:", flashToBaseRatio)
```