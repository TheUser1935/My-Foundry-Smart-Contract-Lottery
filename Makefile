-include .env

fb :;	forge build

ft :; forge test 

fs :; forge snapshot

format :; forge fmt

# Clean the repo
clean  :; forge clean

# Install Dependencies
install:; forge install Cyfrin/foundry-devops --no-commit && forge install transmissions11/solmate --no-commit && forge install foundry-rs/forge-std --no-commit && forge install smartcontractkit/chainlink-brownie-contracts --no-commit

dp-sepolia:
	forge script script/DeployFundMe.s.sol:DeployRaffle --rpc-url $(SEPOLIA_ALCHEMY_RPC_URL) --private-key $(SEPOLIA_METAMASK_PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv

help:
	@echo "Usage:"
	@echo "  make deploy [ARGS=...]\n    example: make deploy ARGS=\"--network sepolia\""
	@echo ""
	@echo "  make fund [ARGS=...]\n    example: make deploy ARGS=\"--network sepolia\""


NETWORK_ARGS := --rpc-url $(ANVIL_RPC_URL) --private-key $(ANVIL_0_PRIVATE_KEY) --broadcast

ifeq ($(findstring --network sepolia,$(ARGS)),--network sepolia)
	NETWORK_ARGS := --rpc-url $(SEPOLIA_ALCHEMY_RPC_URL) --private-key $(SEPOLIA_METAMASK_PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
endif

anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

# Update Dependencies
update:; forge update

deploy:
	@forge script script/DeployRaffle.s.sol:DeployRaffle $(NETWORK_ARGS)

createSubscription:
	@forge script script/Interactions.s.sol:CreateSubscription $(NETWORK_ARGS)

addConsumer:
	@forge script script/Interactions.s.sol:AddConsumer $(NETWORK_ARGS)

fundSubscription:
	@forge script script/Interactions.s.sol:FundSubscription $(NETWORK_ARGS)
