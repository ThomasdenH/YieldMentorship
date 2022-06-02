/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import { Signer, utils, Contract, ContractFactory, Overrides } from "ethers";
import type { Provider, TransactionRequest } from "@ethersproject/providers";
import type { ERC20Mock, ERC20MockInterface } from "../ERC20Mock";

const _abi = [
  {
    inputs: [
      {
        internalType: "string",
        name: "name",
        type: "string",
      },
      {
        internalType: "string",
        name: "symbol",
        type: "string",
      },
    ],
    stateMutability: "nonpayable",
    type: "constructor",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "owner",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "spender",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "value",
        type: "uint256",
      },
    ],
    name: "Approval",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "from",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "to",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "value",
        type: "uint256",
      },
    ],
    name: "Transfer",
    type: "event",
  },
  {
    inputs: [],
    name: "DOMAIN_SEPARATOR",
    outputs: [
      {
        internalType: "bytes32",
        name: "",
        type: "bytes32",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "PERMIT_TYPEHASH",
    outputs: [
      {
        internalType: "bytes32",
        name: "",
        type: "bytes32",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "owner",
        type: "address",
      },
      {
        internalType: "address",
        name: "spender",
        type: "address",
      },
    ],
    name: "allowance",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "spender",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "wad",
        type: "uint256",
      },
    ],
    name: "approve",
    outputs: [
      {
        internalType: "bool",
        name: "",
        type: "bool",
      },
    ],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "guy",
        type: "address",
      },
    ],
    name: "balanceOf",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "from",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
    ],
    name: "burn",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "decimals",
    outputs: [
      {
        internalType: "uint8",
        name: "",
        type: "uint8",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "deploymentChainId",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "to",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
    ],
    name: "mint",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "name",
    outputs: [
      {
        internalType: "string",
        name: "",
        type: "string",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    name: "nonces",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "owner",
        type: "address",
      },
      {
        internalType: "address",
        name: "spender",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "deadline",
        type: "uint256",
      },
      {
        internalType: "uint8",
        name: "v",
        type: "uint8",
      },
      {
        internalType: "bytes32",
        name: "r",
        type: "bytes32",
      },
      {
        internalType: "bytes32",
        name: "s",
        type: "bytes32",
      },
    ],
    name: "permit",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "symbol",
    outputs: [
      {
        internalType: "string",
        name: "",
        type: "string",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "totalSupply",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "dst",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "wad",
        type: "uint256",
      },
    ],
    name: "transfer",
    outputs: [
      {
        internalType: "bool",
        name: "",
        type: "bool",
      },
    ],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "src",
        type: "address",
      },
      {
        internalType: "address",
        name: "dst",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "wad",
        type: "uint256",
      },
    ],
    name: "transferFrom",
    outputs: [
      {
        internalType: "bool",
        name: "",
        type: "bool",
      },
    ],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "version",
    outputs: [
      {
        internalType: "string",
        name: "",
        type: "string",
      },
    ],
    stateMutability: "pure",
    type: "function",
  },
];

const _bytecode =
  "0x610120604052600360e0819052623f3f3f60e81b61010090815262000026919081620001d7565b50604080518082019091526003808252623f3f3f60e81b60209092019182526200005391600491620001d7565b506005805460ff191660121790557f6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c96080523480156200009257600080fd5b506040516200127d3803806200127d833981016040819052620000b5916200034a565b818160128282828260039080519060200190620000d4929190620001d7565b508151620000ea906004906020850190620001d7565b506005805460ff191660ff9290921691909117905550504660c0819052620001129062000121565b60a05250620004939350505050565b60007f8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f6003604051620001559190620003f0565b60408051918290038220828201825260018352603160f81b602093840152815180840194909452838201527fc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6606084015260808301949094523060a0808401919091528451808403909101815260c09092019093528051920191909120919050565b828054620001e590620003b4565b90600052602060002090601f01602090048101928262000209576000855562000254565b82601f106200022457805160ff191683800117855562000254565b8280016001018555821562000254579182015b828111156200025457825182559160200191906001019062000237565b506200026292915062000266565b5090565b5b8082111562000262576000815560010162000267565b634e487b7160e01b600052604160045260246000fd5b600082601f830112620002a557600080fd5b81516001600160401b0380821115620002c257620002c26200027d565b604051601f8301601f19908116603f01168101908282118183101715620002ed57620002ed6200027d565b816040528381526020925086838588010111156200030a57600080fd5b600091505b838210156200032e57858201830151818301840152908201906200030f565b83821115620003405760008385830101525b9695505050505050565b600080604083850312156200035e57600080fd5b82516001600160401b03808211156200037657600080fd5b620003848683870162000293565b935060208501519150808211156200039b57600080fd5b50620003aa8582860162000293565b9150509250929050565b600181811c90821680620003c957607f821691505b602082108103620003ea57634e487b7160e01b600052602260045260246000fd5b50919050565b600080835481600182811c9150808316806200040d57607f831692505b602080841082036200042d57634e487b7160e01b86526022600452602486fd5b818015620004445760018114620004565762000485565b60ff1986168952848901965062000485565b60008a81526020902060005b868110156200047d5781548b82015290850190830162000462565b505084890196505b509498975050505050505050565b60805160a05160c051610d9e620004df60003960008181610272015281816103a6015261052b0152600081816103dc015261056001526000818161017b01526104a20152610d9e6000f3fe608060405234801561001057600080fd5b506004361061010b5760003560e01c806354fd4d50116100a25780639dc29fac116100715780639dc29fac14610247578063a9059cbb1461025a578063cd0d00961461026d578063d505accf14610294578063dd62ed3e146102a757600080fd5b806354fd4d50146101d957806370a08231146101f65780637ecebe001461021f57806395d89b411461023f57600080fd5b806330adf81f116100de57806330adf81f14610176578063313ce5671461019d5780633644e515146101bc57806340c10f19146101c457600080fd5b806306fdde0314610110578063095ea7b31461012e57806318160ddd1461015157806323b872dd14610163575b600080fd5b6101186102e0565b6040516101259190610ab4565b60405180910390f35b61014161013c366004610b25565b61036e565b6040519015158152602001610125565b6000545b604051908152602001610125565b610141610171366004610b4f565b610382565b6101557f000000000000000000000000000000000000000000000000000000000000000081565b6005546101aa9060ff1681565b60405160ff9091168152602001610125565b6101556103a2565b6101d76101d2366004610b25565b6103fe565b005b6040805180820190915260018152603160f81b6020820152610118565b610155610204366004610b8b565b6001600160a01b031660009081526001602052604090205490565b61015561022d366004610b8b565b60066020526000908152604090205481565b61011861040d565b6101d7610255366004610b25565b61041a565b610141610268366004610b25565b610424565b6101557f000000000000000000000000000000000000000000000000000000000000000081565b6101d76102a2366004610ba6565b610431565b6101556102b5366004610c19565b6001600160a01b03918216600090815260026020908152604080832093909416825291909152205490565b600380546102ed90610c4c565b80601f016020809104026020016040519081016040528092919081815260200182805461031990610c4c565b80156103665780601f1061033b57610100808354040283529160200191610366565b820191906000526020600020905b81548152906001019060200180831161034957829003601f168201915b505050505081565b600061037b3384846106a5565b9392505050565b600061038e848361070e565b5061039a8484846107b7565b949350505050565b60007f000000000000000000000000000000000000000000000000000000000000000046146103d9576103d4466108a6565b905090565b507f000000000000000000000000000000000000000000000000000000000000000090565b610408828261095a565b505050565b600480546102ed90610c4c565b61040882826109f4565b600061037b3384846107b7565b428410156104865760405162461bcd60e51b815260206004820152601d60248201527f45524332305065726d69743a206578706972656420646561646c696e6500000060448201526064015b60405180910390fd5b6001600160a01b038716600090815260066020526040812080547f0000000000000000000000000000000000000000000000000000000000000000918a918a918a9190866104d383610c9c565b909155506040805160208101969096526001600160a01b0394851690860152929091166060840152608083015260a082015260c0810186905260e00160405160208183030381529060405280519060200120905060007f0000000000000000000000000000000000000000000000000000000000000000461461055e57610559466108a6565b610580565b7f00000000000000000000000000000000000000000000000000000000000000005b60405161190160f01b602082015260228101919091526042810183905260620160408051601f198184030181528282528051602091820120600080855291840180845281905260ff89169284019290925260608301879052608083018690529092509060019060a0016020604051602081039080840390855afa15801561060b573d6000803e3d6000fd5b5050604051601f1901519150506001600160a01b038116158015906106415750896001600160a01b0316816001600160a01b0316145b61068d5760405162461bcd60e51b815260206004820152601e60248201527f45524332305065726d69743a20696e76616c6964207369676e61747572650000604482015260640161047d565b6106988a8a8a6106a5565b5050505050505050505050565b6001600160a01b03838116600081815260026020908152604080832094871680845294825280832086905551858152919392917f8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b92591015b60405180910390a35060019392505050565b60006001600160a01b03831633146107ae576001600160a01b038316600090815260026020908152604080832033845290915290205460001981146107ac578281101561079d5760405162461bcd60e51b815260206004820152601c60248201527f45524332303a20496e73756666696369656e7420617070726f76616c00000000604482015260640161047d565b6107aa84338584036106a5565b505b505b50600192915050565b6001600160a01b03831660009081526001602052604081205482111561081f5760405162461bcd60e51b815260206004820152601b60248201527f45524332303a20496e73756666696369656e742062616c616e63650000000000604482015260640161047d565b6001600160a01b038085166000908152600160205260408082208054869003905591851681522054610852908390610cb5565b6001600160a01b0380851660008181526001602052604090819020939093559151908616907fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef906106fc9086815260200190565b60007f8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f60036040516108d89190610ccd565b60408051918290038220828201825260018352603160f81b602093840152815180840194909452838201527fc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6606084015260808301949094523060a0808401919091528451808403909101815260c09092019093528051920191909120919050565b6001600160a01b03821660009081526001602052604081205461097e908390610cb5565b6001600160a01b038416600090815260016020526040812091909155546109a6908390610cb5565b60009081556040518381526001600160a01b03851691907fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef906020015b60405180910390a350600192915050565b6001600160a01b038216600090815260016020526040812054821115610a5c5760405162461bcd60e51b815260206004820152601b60248201527f45524332303a20496e73756666696369656e742062616c616e63650000000000604482015260640161047d565b6001600160a01b03831660008181526001602090815260408083208054879003905582548690038355518581529192917fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef91016109e3565b600060208083528351808285015260005b81811015610ae157858101830151858201604001528201610ac5565b81811115610af3576000604083870101525b50601f01601f1916929092016040019392505050565b80356001600160a01b0381168114610b2057600080fd5b919050565b60008060408385031215610b3857600080fd5b610b4183610b09565b946020939093013593505050565b600080600060608486031215610b6457600080fd5b610b6d84610b09565b9250610b7b60208501610b09565b9150604084013590509250925092565b600060208284031215610b9d57600080fd5b61037b82610b09565b600080600080600080600060e0888a031215610bc157600080fd5b610bca88610b09565b9650610bd860208901610b09565b95506040880135945060608801359350608088013560ff81168114610bfc57600080fd5b9699959850939692959460a0840135945060c09093013592915050565b60008060408385031215610c2c57600080fd5b610c3583610b09565b9150610c4360208401610b09565b90509250929050565b600181811c90821680610c6057607f821691505b602082108103610c8057634e487b7160e01b600052602260045260246000fd5b50919050565b634e487b7160e01b600052601160045260246000fd5b600060018201610cae57610cae610c86565b5060010190565b60008219821115610cc857610cc8610c86565b500190565b600080835481600182811c915080831680610ce957607f831692505b60208084108203610d0857634e487b7160e01b86526022600452602486fd5b818015610d1c5760018114610d2d57610d5a565b60ff19861689528489019650610d5a565b60008a81526020902060005b86811015610d525781548b820152908501908301610d39565b505084890196505b50949897505050505050505056fea264697066735822122061d3b50f119eda2403b25f5eb632adf8d854f91753a8d47681fe7fd32e11544a64736f6c634300080d0033";

type ERC20MockConstructorParams =
  | [signer?: Signer]
  | ConstructorParameters<typeof ContractFactory>;

const isSuperArgs = (
  xs: ERC20MockConstructorParams
): xs is ConstructorParameters<typeof ContractFactory> => xs.length > 1;

export class ERC20Mock__factory extends ContractFactory {
  constructor(...args: ERC20MockConstructorParams) {
    if (isSuperArgs(args)) {
      super(...args);
    } else {
      super(_abi, _bytecode, args[0]);
    }
  }

  override deploy(
    name: string,
    symbol: string,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ERC20Mock> {
    return super.deploy(name, symbol, overrides || {}) as Promise<ERC20Mock>;
  }
  override getDeployTransaction(
    name: string,
    symbol: string,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(name, symbol, overrides || {});
  }
  override attach(address: string): ERC20Mock {
    return super.attach(address) as ERC20Mock;
  }
  override connect(signer: Signer): ERC20Mock__factory {
    return super.connect(signer) as ERC20Mock__factory;
  }

  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): ERC20MockInterface {
    return new utils.Interface(_abi) as ERC20MockInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): ERC20Mock {
    return new Contract(address, _abi, signerOrProvider) as ERC20Mock;
  }
}