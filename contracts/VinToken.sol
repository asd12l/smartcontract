pragma solidity 0.4.15;

import "./LockableToken.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "zeppelin-solidity/contracts/ownership/Contactable.sol";


contract VinToken is Contactable {
    using SafeMath for uint;

    string constant public name = "VIN";
    string constant public symbol = "VIN";
    uint constant public decimals = 18;
    uint constant public totalSupply = (10 ** 9) * (10 ** decimals); // 1 000 000 000 VIN
    uint constant public lockPeriod1 = 2 years;
    uint constant public lockPeriod2 = 24 weeks;
    uint constant public lockPeriodForBuyers = 12 weeks;

    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;
    bool public isActivated = false;
    mapping (address => bool) public whitelistedBeforeActivation;
    mapping (address => bool) public isPresaleBuyer;
    address public saleAddress;
    address public founder1Address;
    address public founder2Address;     
    uint public icoEndTime;
    uint public icoStartTime;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint value);

    function VinToken(
        address _founder1Address,
        address _founder2Address,
        uint _icoStartTime,
        uint _icoEndTime
        ) public 
    {
        require(_founder1Address != 0x0);
        require(_founder2Address != 0x0);
        require(_icoEndTime > _icoStartTime);
        founder1Address = _founder1Address;
        founder2Address = _founder2Address;
        icoStartTime = _icoStartTime;
        icoEndTime = _icoEndTime;
        balances[owner] = totalSupply;
        whitelistedBeforeActivation[owner] = true;
    }

    modifier whenActivated() {
        require(isActivated || whitelistedBeforeActivation[msg.sender]);
        _;
    }
    
    modifier isLockTimeEnded(address from){
        if (from == founder1Address) {
            require(now > icoEndTime + lockPeriod1);
        } else if (from == founder2Address) {
            require(now > icoEndTime + lockPeriod2);
        } else if (isPresaleBuyer[from]) {
            require(now > icoEndTime + lockPeriodForBuyers);
        }
        _;
    }

    modifier onlySaleConract(){
        require(msg.sender == saleAddress);
        _;
    }

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint _value) external isLockTimeEnded(msg.sender) whenActivated returns (bool) {
        require(_to != 0x0);
    
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) external constant returns (uint balance) {
        return balances[_owner];
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     *
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint _value) external whenActivated returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address _spender) external constant returns (uint remaining) {
        return allowed[_owner][_spender];
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint _value) external isLockTimeEnded(_from) whenActivated returns (bool) {
        require(_to != 0x0);
        uint _allowance = allowed[_from][msg.sender];

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        
        // _allowance.sub(_value) will throw if _value > _allowance
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);

        return true;
    }

    /**
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     */
    function increaseApproval(address _spender, uint _addedValue) external whenActivated returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) external whenActivated returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * Activation of the token allows all tokenholders to operate with the token
     */
    function activate() external onlyOwner returns (bool) {
        isActivated = true;
        return true;
    }

    /**
     * allows to add and exclude addresses from whitelistedBeforeActivation list for owner
     * @param isWhitelisted is true for adding address into whitelist, false - to exclude
     */
    function editWhitelist(address _address, bool isWhitelisted) external onlyOwner returns (bool) {
        whitelistedBeforeActivation[_address] = isWhitelisted;
        return true;        
    }

    function addToTimeLockedList(address addr) external onlySaleConract returns (bool) {
        require(addr != 0x0);
        isPresaleBuyer[addr] = true;
        return true;
    }

    function setSaleAddress(address newSaleAddress) external onlyOwner returns (bool) {
        require(newSaleAddress != 0x0);
        saleAddress = newSaleAddress;
        return true;
    }

    function setIcoEndTime(uint newTime) external onlyOwner returns (bool) {
        require(newTime > icoStartTime);
        icoEndTime = newTime;
        return true;
    }
}