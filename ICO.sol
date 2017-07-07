pragma solidity ^0.4.11;

import './SafeMath.sol';

contract NertiaToken(){
	uint256 public totalSupply;
	address public constant nertiaOwner;
    transferFrom(address _from, address _to, uint256 _value);
}


/**
 * ICO contract for the Nertia Token
 */
contract ICO {

	using SafeMath for uint256;

	address public constant ethOwner    = 0x88eb247D39BE82a6826a7136058Dd2204969ae67;

	mapping(address => uint256) etherBlance;

	uint256 public constant nertiaSHFunds     = 10 * (10**6) * 10**decimals;
    uint256 public constant icoMinCap  = 25 * (10**6) * 10**decimals;
    
    bool public isFinalized;
    uint256 public icoStartBlock;
    uint256 public icoEndBlock;
    uint256 public icoStartTime;

    event Refund(address indexed _to, uint256 _value);
    event RefundError(address indexed _to, uint256 _value);
    
	function ICO(uint256 _icoEndBlock) {
		isFinalized    = false;
		icoStartTime   = now;
		icoStartBlock  = block.number;
		icoEndBlock    = _icoEndBlock;
	}

	function () payable() {
		if(isFinalized && msg.value <= 0) throw;

		if(block.number < icoStartBlock) throw;
		if(block.number > icoEndBlock) throw;

		// storing user ethers;
		etherBlance[msg.sender] = msg.value;

		// calculating bonus
		uint256 bonus  =  calcBonus(msg.value);
		uint256 amount = msg.value.add(bonus);
		transferFrom(nertiaOwner,msg.sender, amount);

	}

	function refund(){
		if(isFinalized) throw;
		if(block.number <= icoEndBlock) throw;
		if(msg.sender == nertiaOwner ) throw;

		uint256 balance = balance[msg.sender];
		if(balance == 0) throw;

		uint256 ether = etherBlance[msg.sender];
		if(ether == 0) throw;
		
		balance[msg.sender] = 0;
		etherBlance[msg.sender] = 0;

		if(msg.sender.send(ether)){
			LogRefund(msg.sender, ether);
		}else{
			balance[msg.sender] = balance;
			etherBlance[msg.sender] = ether;
			RefundError(msg.sender, ether)
			throw;
		}
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
}
