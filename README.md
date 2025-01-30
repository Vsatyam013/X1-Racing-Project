# X1-Racing-Project

## Overview
The **X1-Racing-Project** project is a smart contract system built on Ethereum, featuring a native token (**x1Coin**) and a staking/minting engine (**x1Engine**). The system allows token minting, staking, rewards distribution, and ownership management with built-in security measures.

## Project Structure
```
root/
├── script/
│   ├── DeployX1Coin.s.sol  # Deployment script using Foundry
├── src/
│   ├── x1Coin.sol          # ERC20 token contract
│   ├── x1Engine.sol        # Staking & minting contract
├── test/
│   ├── x1CoinTest.t.sol    # Foundry tests for x1Coin & x1Engine
├── foundry.toml            # Foundry configuration file
├── README.md               # Project documentation
```

## Deployment
### **Using Foundry**
1. **Install Foundry (if not installed):**
   ```sh
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   ```
2. **Set up environment variables:**
   ```sh
   export PRIVATE_KEY=your_private_key_here
   ```
3. **Run the deployment script:**
   ```sh
   forge script script/DeployX1Coin.s.sol --rpc-url YOUR_RPC_URL --broadcast --private-key $PRIVATE_KEY
   ```

## Testing
Run the Foundry test suite with:
```sh
forge test -vv
```
This will execute all tests in `test/x1CoinTest.t.sol`, ensuring contract functionality.

## Key Features
- **ERC20 Token:** `x1Coin` is the native token with minting and burning capabilities.
- **Staking & Rewards:** Users can stake tokens and earn rewards after a set period.
- **Minting Control:** Allocations for team, community, and public minting with enforced limits.
- **Security Measures:** Includes ownership checks, access control, and time-based restrictions.

## Smart Contracts
### **x1Coin.sol** (ERC20 Token)
- Implements an ERC20 token with minting and burning functionalities.
- Restricted access control to prevent unauthorized minting/burning.
- Ownership can be transferred to another address.

### **x1Engine.sol** (Staking & Minting Engine)
- Manages minting allocations (team, community, public).
- Implements staking with a minimum lock-up period.
- Distributes rewards based on a predefined rate.
- Enforces security checks such as:
  - **x1Engine__InsufficientContractBalance** (prevents unstaking if funds are insufficient)
  - **x1Engine__TokensLocked** (prevents early team minting)
  - **x1Engine__ExceedsAllocation** (ensures minting stays within limits)

## License
This project is licensed under the MIT License.

---
For further improvements or issues, feel free to open a pull request or create an issue!

