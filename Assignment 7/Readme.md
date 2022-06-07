# Deploy
To test deployment, use `anvil`:
```sh
anvil --fork-url https://kovan.infura.io/v3/6f4f43507fa24302a651b52073c98d8a
forge script script/Deploy.sol --fork-url http://127.0.0.1:8545 --sender 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266 --broadcast --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```
(Private key belongs to default test seed.)
