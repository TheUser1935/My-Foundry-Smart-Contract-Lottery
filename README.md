# Cyfrin Course

# Smart Contract Lottery

## About

This is my version of the smart contract lottery that is covered in the Cyfrin Updraft Learning Platform. It contains plenty of comments that I use to aide my understanding and is not an accurate representaiton of industry standard - this is my learning journey.

## Goals of the smart contract lottery

1. Users can enter by paying for a ticket
   1. The ticket fees are going to go to the winner of the draw
2. After X period of time, the lottery will automatically draw a winner
   1. This is will be done programatically
3. Project will use Chainlink VRF & Chainlink automation for two purposes:
   1. Chainlink VRF - used for randomness
   2. Chainlink automation - used for time based trigger


# Chainlink Dependencies

### Chainlink Repos

Project uses the brownie contracts kit provided by chainlink. The brownie contracts are smaller that the standard smartcontractkit repo

### To install from Terminal run the following (updating the @version as required)
``` shell
$ forge install smartcontractkit/chainlink-brownie-contracts@0.8.0 --no-commit
```


# Foundry Information

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

  ## ENVIRONMENT VARIABLES

### FROM TERMINAL, WE WANT FORGE TO REFER TO OUR .ENV FILE. TO DO THIS:
```shell
$ source .env
```

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

## Cast

```shell
$ cast <subcommand>
```

### Cast Function Signature

- Will return hexadecimal value
- Allows to check that we are doing what we expect to be doing- e.g check hex data in metamask against the hex value of function name to verify correct function is being called

```shell
$ cast sig "functionName()"
```

### Cast Using CallData Decode

- This is used to achieve the same goal of 'cast sig', however, this is used for functions that have parameters which makes the hex string much larger
- This would return what each of the parameters are for the function

```shell
$ cast --calldata-decode "functionName()" HexString(e.g.2a4d5b etc etc)
```


### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```


## Development

This project uses [Foundry](https://getfoundry.sh). See the [book](https://book.getfoundry.sh/getting-started/installation.html) for instructions on how to install and use Foundry.
