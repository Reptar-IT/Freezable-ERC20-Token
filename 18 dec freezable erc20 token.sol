pragma solidity ^0.4.25;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
//give ownership to creator
contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  constructor () public {
    owner = msg.sender;
   }
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}
contract tokenRecipient { 
    function receiveApproval (address _from, uint256 _value, address _token, bytes _extraData) public; 
}
contract Azzle is Ownable {
    using SafeMath for uint256; 
    string public name; 
    string public symbol; 
    uint256 public decimals;  
    uint256 public totalSupply; 
    address public beneficiary;
    uint256 public burnt;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public frozenAccount;
    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed burner, uint256 value);
    event Burnfrom(address indexed _from, uint256 value);
    constructor() public {
        name = "Azzle";    
        symbol = "AZL";    
        decimals = 18;
        burnt = 0; 
        totalSupply = 25000000 * (10 ** decimals);
        beneficiary = msg.sender;
        balanceOf[beneficiary] = totalSupply;
    }
    function nameChange(string _name, string _symbol) public onlyOwner {
        name = _name;
        symbol = _symbol;
    }
    function transfer(address _to, uint256 _value) public {
        if (frozenAccount[msg.sender]) revert(); 
        if (balanceOf[msg.sender] < _value) revert() ;           
        if (balanceOf[_to] + _value < balanceOf[_to]) revert(); 
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value); 
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);          
    }
    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }
    /* Approve and then communicate the approved contract in a single tx */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public
        returns (bool success) {    
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (frozenAccount[_from]) revert();                        // Check if frozen  
        if (balanceOf[_from] < _value) revert();                
        if (balanceOf[_to] + _value < balanceOf[_to]) revert(); 
        if (_value > allowance[_from][msg.sender]) revert(); 
        balanceOf[_from] = balanceOf[_from].sub(_value);                     
        balanceOf[_to] = balanceOf[_to].add(_value);                          
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    function burn(uint256 _value) public {
        require(_value <= balanceOf[msg.sender]);
        address burner = msg.sender;
        balanceOf[burner] = balanceOf[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        burnt = burnt.add(_value);
        emit Burn(burner, _value);
        emit Transfer(burner, address(0), _value);
    }
    function burnFrom(address _from, uint256 _value) public onlyOwner payable returns  (bool success) {
        require (balanceOf[_from] >= _value);            
        require (msg.sender == owner);   
        totalSupply = totalSupply.sub(_value);
        burnt = burnt.add(_value);
        balanceOf[_from] = balanceOf[_from].sub(_value);                      
        emit Burnfrom(_from, _value);
        return true;
    }
    function freezeAccount(address target, bool freeze) public onlyOwner {
        require (msg.sender == owner);   // Check allowance
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }
    function unFreezeAccount(address target, bool freeze) public onlyOwner {
        require (msg.sender == owner);   // Check allowance
        require(frozenAccount[target] = freeze);
        frozenAccount[target] = !freeze;
        emit FrozenFunds(target, !freeze);
    }
    function () private {
        revert();  
    }
}