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

# Design Principles

1.  In functions, use CEI: Checks, Effects, Interactions
    1.  Checks - require statements, if -> error statements
    2.  Effects - Effects on OWN contract
    3.  Interactions - Other contracts
2.  Adhere to Solidity Style Guide as much as possible

# Sepolia Etherscan Verified Deployements

1. 02 MAR 24 ~10:00pm - Deployed Raffle contract as part of course work, project not yet complete. Successfully deployed Raffle project and integrated with Chainlink VRF by adding consumer to the Subscription ID supplied. Have created a chainlink automation Upkeep for the Raffle contract, as of 10:25pm there has been no automated upkeep performed.
   - https://sepolia.etherscan.io/address/0x9f4495fff8a73c7fefd8aeb5bc772dc6c3f4af4b#code

# Chainlink Dependencies

### Chainlink Repos

Project uses the brownie contracts kit provided by chainlink. The brownie contracts are smaller that the standard smartcontractkit repo

### To install from Terminal run the following (updating the @version as required)

```shell
$ forge install smartcontractkit/chainlink-brownie-contracts@0.8.0 --no-commit
```

# Foundry Information

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

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

## Solidity Dev Tips

### Call Command and Revert

This is a lower level command is able to call just about any function without needing an ABI, for now just going to focus on sending ETH

Call is also the reccomended method currently for sending value
The ("") is used to type in a function name that we might want to call, not useful for this though
We always see that "Value" exists on the L side of Remix - this is what we want
This line returns 2 variables - bool (success), bytes (data returned)
We don't care about the bytes though in this example, so we leave it blank

Have to ways of verifying the call command:

1.  require statement
2.  if statement
    Preferred method at this time is using if statements due to ability to gas efficiencies that can be achieved and can use custom errors (e.g. custom error called Raffle_TransferToWinnerFailed)

```shell
(bool success, ) = payable(msg.sender).call{
   value: address(this).balance
}("");
if (!success) {
   revert Raffle_TransferToWinnerFailed();
}
require(callSuccess, "Call failed");
```

### Enum Types

Enums can be used to create custom types with finite set of 'constant values'

Enums are one way to create a user-defined type in Solidity. They are explicitly convertible to and from all integer types but implicit conversion is not allowed. The explicit conversion from integer checks at runtime that the value lies inside the range of the enum and causes a Panic error otherwise. Enums require at least one member, and its default value when declared is the first member. Enums cannot have more than 256 members. Each constant supplied is mapped to an index integer, beginning from zero

Using type(NameOfEnum).min and type(NameOfEnum).max you can get the smallest and respectively largest value of the given enum

```shell

enum State {
   Created, //0
   Locked, //1
   Inactive //2
} // Enum

enum ActionChoices { GoLeft, GoRight, GoStraight, SitStill }

ActionChoices choice;
ActionChoices constant defaultChoice = ActionChoices.GoStraight;

function setGoStraight() public {
   choice = ActionChoices.GoStraight;
}

// Since enum types are not part of the ABI, the signature of "getChoice"
// will automatically be changed to "getChoice() returns (uint8)"
// for all matters external to Solidity.
function getChoice() public view returns (ActionChoices) {
   return choice;
}

function getDefaultChoice() public pure returns (uint) {
   return uint(defaultChoice);
}

function getLargestValue() public pure returns (ActionChoices) {
   return type(ActionChoices).max;
}

function getSmallestValue() public pure returns (ActionChoices) {
   return type(ActionChoices).min;
}


```

## Development

This project uses [Foundry](https://getfoundry.sh). See the [book](https://book.getfoundry.sh/getting-started/installation.html) for instructions on how to install and use Foundry.

## Tests

### Components for testing

1. Deploy Script to be able to deploy our contract to various chains
2. Tests that are compatible across different chains
3. Chains to test on:
   1. Local (anvil and ganache)
   2. Forked testnet (Sepolia)
   3. Forked Mainnet

### vm.recordLogs()

vm.recordLogs(); is a cheatcode that tells the VM to start recording all the emitted events as bytes32. To access them, use getRecordedLogs
------> this is handy in the situation where we want to test the emit but the result will be dynamic and not static, which is an issue for expectEmit process.
------> This way is handy to capture the log output where can test the emit process

vm.recordLogs() will create a special array that contains all the emitted events. To access the logs we need to:

1.  import {Vm} from forge-std/Vm.sol
2.  Vm.Log[] memory ARRAY_NAME = vm.getRecordedLogs();

We can then access the recorded logs to find the emitted events we are after in our test. When we look for the emit value, we can pass in the value to match.
-----> If there is multiple entries that feature the same name/value, it becomes important to understand the order in which the logs are emitted (index begins at zero)
-----> In this contract, the VRFCoordinatorV2 emits requestId first, but we are trying to target the request id emmitted during performUpkeep

### forge test --debug Function_Name

--debug will open up a step through debugger window that can allow user to literally go opcode by opcode through the test. This allows granular examination of what is occuring during the test.

It will be covered in greater detail later in the course.
