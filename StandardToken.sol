pragma solidity ^0.4.11;

import './SafeMath.sol';

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

contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }
/*  ERC 20 token */
contract StandardToken is Token {
    
    mapping (address => uint256) balanceOf;    
    mapping (address => mapping (address => uint256)) allowed;

    function transfer(address _to, uint256 _value) returns (bool success) {
      if (_to == 0x0) return false;
      if (balanceOf[msg.sender] >= _value && _value > 0) {
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
      if (balanceOf[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
        balanceOf[_to] += _value;
        balanceOf[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balanceOf[_owner];
    }

    

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value)
        returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        return true;
    }

    /* Approve and then communicate the approved contract in a single transaction */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }    
}