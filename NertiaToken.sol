pragma solidity ^0.4.11;

import './StandardToken.sol';

contract NertiaToken is StandardToken {
    
    mapping (address => bool) public frozenAccount;
    using SafeMath for uint256;
    // metadata
    string public constant name = "Nertia";
    string public constant symbol = "₦";
    uint256 public constant decimals = 18;
    string public constant version = "1.0";

    // contracts
    address public ethFundDeposit;      // deposit address for ETH for Organization
    address public nertiaFundDeposit;      // deposit address for Organization use and Nertia User Fund

    // crowdsale parameters
    bool public isFinalized;              // switched to true in operational state
    uint256 public fundingStartBlock;
    uint256 public fundingEndBlock;
    uint256 public constant nertiaFund = 40 * (10**6) * 10**decimals;   // 40m Nertia reserved for Organization use
    uint256 public constant nertiaSHFunds = 10 * (10**6) * 10**decimals;
    uint256 public tokenExchangeRate = 310; // 310 Nertia tokens per 1 ETH
    uint256 public constant tokenCreationCap =  100 * (10**6) * 10**decimals;
    uint256 public constant tokenCreationMin =  25 * (10**6) * 10**decimals;
    uint256 public startingTime;
    uint256 public _fundingStartBlock;
    uint256 public _fundingEndBlock;
    
    // only owner modifer
    modifier onlyOwner {if (msg.sender != nertiaFundDeposit) throw; _;}    
    // events
    event LogRefund(address indexed _to, uint256 _value);
    event CreateNertia(address indexed _to, uint256 _value);

    // constructor
    function NertiaToken(address _ethFundDeposit, address _nertiaFundDeposit){
      
      _fundingStartBlock = block.number;
      _fundingEndBlock = _fundingStartBlock.add(10000);
      startingTime = now;
      isFinalized = false;                   //controls pre through crowdsale state
      ethFundDeposit = _ethFundDeposit;
      nertiaFundDeposit = _nertiaFundDeposit;
      fundingStartBlock = _fundingStartBlock;
      fundingEndBlock = _fundingEndBlock;
      totalSupply = nertiaFund.add(nertiaSHFunds);
      balances[nertiaFundDeposit] = nertiaFund;    // Deposit Organization share
      nertiaShareHolders();
      CreateNertia(nertiaFundDeposit, nertiaFund);  // logs Organization fund
    }

    /// @dev Accepts ether and creates new Nertia tokens.
    function createTokens() payable external {
      if (isFinalized && msg.value <= 0) throw;
      if (block.number < fundingStartBlock) throw;
      if (block.number > fundingEndBlock) throw;
      
      // calculating bouns 
      uint256 amount = msg.value.add(calcBonus(msg.value));

      // return money if insuccefficent balance.
      if(balances[nertiaFundDeposit] < amount) throw;

      uint256 tokens = amount.mul(tokenExchangeRate);
      uint256 checkedSupply = totalSupply.add(tokens);

      // return money if something goes wrong
      if (tokenCreationCap < checkedSupply) throw; 
      
      totalSupply = checkedSupply;
      transferFrom(nertiaFundDeposit, msg.sender, tokens);
      CreateNertia(msg.sender, tokens);  // logs token creation
    }

    /// @dev Ends the funding period and sends the ETH home
    function finalize() external {
      if (isFinalized) throw;
      if (msg.sender != ethFundDeposit) throw; // locks finalize to the ultimate ETH owner
      if(totalSupply < tokenCreationMin) throw;      // have to sell minimum to move to operational
      if(block.number <= fundingEndBlock && totalSupply != tokenCreationCap) throw;
      // move to operational
      isFinalized = true;
      if(!ethFundDeposit.send(this.balance)) throw;  // send the eth to the Organization.
    }

    /// @dev Allows contributors to recover their ether in the case of a failed funding campaign.
    function refund() external {
      if(isFinalized) throw;                       // prevents refund if operational
      if (block.number <= fundingEndBlock) throw; // prevents refund until sale period is over
      if(totalSupply >= tokenCreationMin) throw;  // no refunds if we sold enough
      if(msg.sender == nertiaFundDeposit) throw;    // Organiztion not entitled to a refund
      uint256 nertiaVal = balances[msg.sender];
      if (nertiaVal == 0) throw;
      balances[msg.sender] = 0;
      totalSupply = totalSupply.sub(nertiaVal); // extra safe
      uint256 ethVal = nertiaVal.div(tokenExchangeRate);
      LogRefund(msg.sender, ethVal);               // log it 
      if (!msg.sender.send(ethVal)) throw;       // if you're using a contract; make sure it works with .send gas limits
    }
    
    
    function calcBonus(uint256 _val) private constant returns (uint256){
            return _val.div(100).mul(getPercentage());            
    }
    
    function bonusType() public constant returns (uint){
        return now.sub(startingTime);
    }   
   
    function getPercentage() public constant returns (uint){
        uint duration = bonusType();
        if(duration > 14 days){
            return 0;
        }else if(duration <= 14 days && duration > 72 hours){
            return 10;
        }else if(duration > 24 hours){
            return 25;
        }else{
            return 50;
        }
    }
    
    function updatePrice(uint256 _price) onlyOwner {
        tokenExchangeRate = _price;  
    }

    function transferOwnership(address _newOwner) onlyOwner {
        nertiaFundDeposit = _newOwner;
    }

    function nertiaShareHolders(){
        uint256 share = nertiaSHFunds.div(2);
        /*balances["0xc72d70E57d99d6a42D0bCfBF5Fff1b18Bd1067BD"] += share;
        balances["0x2a8C332CFf2bB93C84bEcc690fFAFfdE803E813e"] += share;
        balances["0xD9E6c5792aAcf76244B01c215F38803d9c46E8cB"] += share;
        balances["0x409A7984535682980b9eB45E235F23fb09cCb975"] += share;
        balances["0x4DBA298F414EefA6430CfBCc051c4956DFb6f60C"] += share;*/  
        balances["0x88eb247D39BE82a6826a7136058Dd2204969ae67"] += share;
        balances["0xe3bec4c30292398960a2C3BbDb6dA2579c287364"] += share;
    }   

}