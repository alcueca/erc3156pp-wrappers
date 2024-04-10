# ERC7399 Flash Lender Wrappers

This repository contains contracts that work as
[ERC7399](https://github.com/ethereum/EIPs/blob/d072207e24e3cc12b6315909e6a65275a38e1984/EIPS/eip-7399.md) entry points
for popular flash lenders.

## How Do These Wrappers Work

```mermaid
sequenceDiagram
  title ERC3156Wrapper
    Borrower->>Wrapper: ERC7399.flash(to,token,amt,data,callback)
    Wrapper->>Lender: lender specific flashLoan call
    Lender-->>Wrapper: transfer loan amount
    Lender->>Wrapper: lender specific callback()
    Wrapper -->>Wrapper: bridgeToCallback()
    Wrapper-->>Borrower: transfer loan amount
    Wrapper->>Borrower: callback()
    Borrower -> Borrower: Borrower does stuff
    Borrower -->> Wrapper: transfer loan amount + fee †
    Borrower ->> Wrapper: callback return
    Wrapper --> Wrapper: approves token repayment to lender †
    Wrapper -->> Lender: lender calls transferFrom(wrapper, amount + fee) †
```

† For the BalancerWrapper and Uniswap v3 the borrower transfers the repayment to the lender and the wrapper skips the
repayment approval.

## Deployments

| Lender                 | Networks                                          | Address                                    | Gas             | Fees     | Contract                                                      |
| ---------------------- | ------------------------------------------------- | ------------------------------------------ | --------------- | -------- | ------------------------------------------------------------- |
| Aave v3                | Arbitrum One, Optimism, Polygon                   | 0x9D4D2C08b29A2Db1c614483cd8971734BFDCC9F2 | 302483          | 0.09%    | [AaveWrapper](src/aave/AaveWrapper.sol)                       |
| Aave v3 (Permissioned) | Ethereum, Gnosis                                  | 0x0c86c636ed5593705b5675d370c831972C787841 | 299756          | 0        | [AaveWrapper](src/aave/AaveWrapper.sol)                       |
| Spark                  | Ethereum, Gnosis                                  | 0x8cB701df93f2Dae295aE8D7beE5Aa7e4D40CB397 | 302483          | 0.09%    | [AaveWrapper](src/aave/AaveWrapper.sol)                       |
| Balancer v2            | Ethereum, Arbitrum One, Optimism, Polygon, Gnosis | 0x9E092cb431e5F1aa70e47e052773711d2Ba4917E | 183039          | 0        | [BalancerWrapper](src/balancer/BalancerWrapper.sol)           |
| Balancer v2            | Base                                              | 0xD534400B0555F8441c5a3e0E9e585615B54fB2F4 | 183039          | 0        | [BalancerWrapper](src/balancer/BalancerWrapper.sol)           |
| Uniswap v3             | Arbitrum One, Optimism, Polygon                   | 0x319300462C37AD2D4f26B584C2b67De51F51f289 | 184417 - 202711 | Variable | [UniswapV3Wrapper](src/uniswapV3/UniswapV3Wrapper.sol)        |
| Balancer + Moonwell    | Base                                              | 0x6207ec38da68902CC60D3760c9fe3EB64B426207 | 1253325         | 0        | [CompoundWrapper](src/compound/CompoundWrapper.sol)           |
| Balancer + Sonne       | Optimism                                          | 0x6412183C579a276f467ad38468D19CC8f1F2b5cb | 1142829         | 0        | [CompoundWrapper](src/compound/CompoundWrapper.sol)           |
| Balancer + Silo        | Arbitrum One                                      | 0x0F9104Fec1a5C91e63632E215e8F5c57C8f32c77 | 1115741         | 1        | [SiloWrapper](src/silo/SiloWrapper.sol)                       |
| Dolomite               | Arbitrum One                                      | 0x54F1ce5E6bdf027C9a6016C9F52fC5A445b77ed6 | 529843          | 0        | [DolomiteWrapper](src/dolomite/DolomiteWrapper.sol)           |
| MorphoBlue             | Ethereum                                          | 0xa0Cb4e1222d813D6e4dE79f2A7A0B7759209588F | 202128          | 0        | [MorphoBlueWrapper](src/morpho/MorphoBlueWrapper.sol)         |
| Camelot                | Arbitrum One                                      | 0x5E8820B2832aD8451f65Fa2CCe2F3Cef29016D0d | 148686 - 155940 | 0.01%    | [AlgebraWrapper](src/algebra/AlgebraWrapper.sol)              |
| Algebra + Pendle       | Arbitrum One                                      | 0xC9d66F655b7B35A2B4958bE2FB58E472736Bbc47 | 596718          | 0.01%    | [AlgebraPendleWrapper](src/pendle/AlgebraPendleWrapper.sol)   |
| Balancer + Pendle      | Arbitrum One                                      | 0xC1Ea6a6df39D991006b39706db7C51f5A1819da7 | 595448          | 0        | [BalancerPendleWrapper](src/pendle/BalancerPendleWrapper.sol) |
| Aerodrome              | Base                                              | 0x69b6E55f00d908018E2D745c524995bc231D762b | 253829 - 314321 | Variable | [SolidlyWrapper](src/solidly/SolidlyWrapper.sol)              |
| Velodrome              | Optimism                                          | 0xcF13CDdbA3aEf757c52466deC310F221e06238d6 | 253829 - 314321 | Variable | [SolidlyWrapper](src/solidly/SolidlyWrapper.sol)              |

Contracts are deployed at the same address for the same lender for all its supported networks.

When a contract requires constructor parameters which vary per network, these are supplied by the
[Registry](https://github.com/alcueca/registry) deployed at 0x1BFf8Eee6ECF1c8155E81dba8894CE9cF49a220c in each supported
network.

Approximate gas costs and fees are provided. For AMMs the fees often vary according to pool parameters and state. Gas
costs can also vary according to state.

## Flash Loans

For detail on executing flash loans, please refer to the
[ERC7399](https://github.com/ethereum/EIPs/blob/d072207e24e3cc12b6315909e6a65275a38e1984/EIPS/eip-7399.md) EIP.

## Using This Repository

This is a list of the most frequently needed commands.

### Build

Build the contracts:

```sh
$ forge build
```

### Clean

Delete the build artifacts and cache directories:

```sh
$ forge clean
```

### Compile

Compile the contracts:

```sh
$ forge build
```

### Coverage

Get a test coverage report:

```sh
$ forge coverage
```

### Deploy

Deploy to Anvil:

```sh
$ forge script script/Deploy.s.sol --broadcast --fork-url http://localhost:8545
```

For this script to work, you need to have a `MNEMONIC` environment variable set to a valid
[BIP39 mnemonic](https://iancoleman.io/bip39/).

For instructions on how to deploy to a testnet or mainnet, check out the
[Solidity Scripting](https://book.getfoundry.sh/tutorials/solidity-scripting.html) tutorial.

### Format

Format the contracts:

```sh
$ forge fmt
```

### Gas Usage

Get a gas report:

```sh
$ forge test --gas-report
```

### Lint

Lint the contracts:

```sh
$ pnpm lint
```

### Test

Run the tests:

```sh
$ forge test
```

## Notes

1. Foundry uses [git submodules](https://git-scm.com/book/en/v2/Git-Tools-Submodules) to manage dependencies. For
   detailed instructions on working with dependencies, please refer to the
   [guide](https://book.getfoundry.sh/projects/dependencies.html) in the book
2. You don't have to create a `.env` file, but filling in the environment variables may be useful when debugging and
   testing against a fork.

## License

This project is licensed under MIT.
