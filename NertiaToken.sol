pragma solidity ^0.4.11;

import './StandardToken.sol';

contract NertiaToken is StandardToken {

	using SafeMath for uint256;

	mapping(address => bool) frozenAccount;
	mapping(address => uint256) bonus;	

	address public constant nertiaOwner = 0x88eb247D39BE82a6826a7136058Dd2204969ae67;

	string  public constant name         = "Nertia";
	string  public constant symbol       = "₦";
	string  public constant version      = "1.0";
	uint256 public constant decimals     = 18;
	uint256 public exchangeRate          = 310;

	 // 40m Nertia reserved for Organization use
	uint256 public nertiaFund      = 40 * (10**6) * 10**decimals;  
    uint256 public totalSupply     = 100 * (10**6) * 10**decimals;
    
    event CreateNertia(address indexed _to, uint256 _value);
    event Burn(address indexed from, uint256 value);

    modifier onlyOwner{ 
    	if ( msg.sender != nertiaOwner) throw; 
    	_; 
    }    

    function NertiaToken(){
    	balanceOf[nertiaOwner] = totalSupply;
    	totalSupply           = totalSupply;
    	CreateNertia(nertiaOwner, totalSupply);
    }

    function () payable external {

    	if(msg.value <= 0) throw;
    	uint256 tokens = msg.value.mul(exchangeRate);    	
    	if(!transferFrom(nertiaOwner, msg,sender, tokens)) throw;
    	CreateNertia(msg.sender, tokens);
	}

	function updatePrice(uint256 _price) onlyOwner {
		exchangeRate = _price;
	}

	function transfer(address _to, uint256 _value) returns (bool success) {
      if (balanceOf[msg.sender] >= _value && _value > 0) {
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function burn(uint256 _value) returns (bool success) {
        if (balanceOf[msg.sender] < _value) throw;            
        balanceOf[msg.sender] -= _value;                      
        totalSupply -= _value;                                
        Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) returns (bool success) {
        if (balanceOf[_from] < _value) throw;                
        if (_value > allowed[_from][msg.sender]) throw;    
        balanceOf[_from] -= _value;                          
        totalSupply -= _value;                               
        Burn(_from, _value);
        return true;
    }

}