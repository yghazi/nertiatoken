pragma solidity ^0.4.11;

library SafeMath {
  function mul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

}

contract Token {
    uint256 public totalSupply;
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


/*  ERC 20 token */
contract StandardToken is Token {
    
    function transfer(address _to, uint256 _value) returns (bool success) {
      if (balances[msg.sender] >= _value && _value > 0) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
      if (balances[_from] >= _value && _value > 0) {
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract NertiaToken is StandardToken {
    
    mapping (address => bool) public frozenAccount;
    using SafeMath for uint256;
    // metadata
    string public constant name = "NertiaT";
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
    bool public transferFrom;
    
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
      uint256 created_tokens = tokenCreationCap.sub(nertiaSHFunds);
      balances[nertiaFundDeposit] = created_tokens;    // Deposit Organization share
      CreateNertia(nertiaFundDeposit, created_tokens);  // logs Organization fund
      nertiaShareHolders();

      
    }

    /// @dev Accepts ether and creates new Nertia tokens.
    function () payable {
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
      
      // return money if transfer is not successfull.
      if(!transferFrom(nertiaFundDeposit, msg.sender, tokens)) throw;

      totalSupply = checkedSupply;
      
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
        //uint256 share = nertiaSHFunds.div(2);
        /*balances["0xc72d70E57d99d6a42D0bCfBF5Fff1b18Bd1067BD"] += share;
        balances["0x2a8C332CFf2bB93C84bEcc690fFAFfdE803E813e"] += share;
        balances["0xD9E6c5792aAcf76244B01c215F38803d9c46E8cB"] += share;
        balances["0x409A7984535682980b9eB45E235F23fb09cCb975"] += share;
        balances["0x4DBA298F414EefA6430CfBCc051c4956DFb6f60C"] += share;*/  
        //balances["0xdb4c3fb46c11b2c9076ca62a4475c8a309f0b37d"] += share;
        //balances["0xd73f84263bcb55b7413bfaa513d7f6a685550ff0"] += share;
    }   

}