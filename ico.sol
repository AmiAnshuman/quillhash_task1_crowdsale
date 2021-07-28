


pragma solidity 0.5.16;



/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


 interface ERC20{
    function totalSupply() external returns (uint);
    function balanceOf(address tokenOwner) external returns (uint balance);
    function allowance(address tokenOwner, address spender) external returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
 
 
interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}
contract Context {

    constructor () internal { }
   
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; 
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred (address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }


    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }


    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


 
contract Crowdsale is Ownable {
  using SafeMath for uint256;


  ERC20 public token;


  address payable public  wallet;

  uint256 public usdRaised;
  
  AggregatorV3Interface internal priceFeed;

  mapping(address => uint256) public contributions;
  mapping(address => bool) public whitelist;
  
  uint256 public openingTime;
  uint256 public closingTime;
  
  bool public running=true;


 
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  
  modifier isWhitelisted(address _beneficiary) {
    require(whitelist[_beneficiary]);
    _;
  }
  

  modifier onlyWhileOpen {
    require(now >= openingTime && now <= closingTime);
    _;
  }
  
  modifier onlyWhileRunning {
    require(running==true);
    _;
  }
  
    constructor () public {
        openingTime=now;
        closingTime=now+62 days;
     priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
  }
  

  function addToWhitelist(address _beneficiary) external onlyOwner {
    whitelist[_beneficiary] = true;
  }

  
  function addManyToWhitelist(address[] calldata _beneficiaries) external onlyOwner {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      whitelist[_beneficiaries[i]] = true;
    }
  }


  function removeFromWhitelist(address _beneficiary) external onlyOwner {
    whitelist[_beneficiary] = false;
  }

  
  
    function () external payable {
    buyTokens(msg.sender);
  }

  
  

    function getLatestPrice() public view returns (int) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }

 
 
 
 
  function buyTokens(address _beneficiary) public payable isWhitelisted(_beneficiary) onlyWhileOpen onlyWhileRunning {

    uint256 weiAmount = msg.value;
    uint256 ethToUsd = uint256(getLatestPrice());
    uint256 BuyValue = weiAmount.mul(ethToUsd) / ( 10**26);
    
    
    _preValidatePurchase( _beneficiary, BuyValue);

    // calculate token amount to be created
    uint256 tokens = _getTokenAmount(weiAmount);
    
    require(token.balanceOf(address(this))>=tokens);

    // update state
    usdRaised = usdRaised.add(BuyValue);

    _processPurchase(_beneficiary, tokens);
    
    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      weiAmount,
      tokens
    );

    _updatePurchasingState(_beneficiary, BuyValue);

    _forwardFunds();
    _postValidatePurchase(_beneficiary, tokens);
  }



  function _preValidatePurchase(address _beneficiary, uint256 usdAmount) internal {
    require(_beneficiary != address(0));
    require(usdAmount>=500, "Minimum value to buy is 500 per investor");
    require(contributions[_beneficiary].add(usdAmount) <= 5000000);
  }



  function _postValidatePurchase(address _beneficiary, uint256 _tokenAmount) internal {
      
    uint256 bonusToken;
    if(now <= openingTime+15 days && now >= openingTime)
    {
        bonusToken=_tokenAmount/4;
        token.transfer(_beneficiary, bonusToken);
    }
    
    else if(now <= openingTime+30 days && now > openingTime+15 days)
    {
        bonusToken=_tokenAmount/5;
        token.transfer(_beneficiary, bonusToken);
    }
    else if(now <= openingTime+38 days && now >openingTime+30 days)
    {
        bonusToken=(_tokenAmount*15/100);
        token.transfer(_beneficiary, bonusToken);
    }
    else if(now <= openingTime+46 days && now >openingTime+38 days)
    {
        bonusToken=_tokenAmount/10;
        token.transfer(_beneficiary, bonusToken);
    }
    else if(now <= openingTime+54 days && now >openingTime+46 days)
    {
        bonusToken=_tokenAmount/20;
        token.transfer(_beneficiary, bonusToken);
    }

  }



  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    token.transfer(_beneficiary, _tokenAmount);
  }



  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    _deliverTokens(_beneficiary, _tokenAmount);
  }



  function _updatePurchasingState(address _beneficiary, uint256 usdAmount) internal {
    contributions[_beneficiary] = contributions[_beneficiary].add(usdAmount);
  }



  function _getTokenAmount(uint256 _weiAmount) public view returns (uint256) {
    uint256 ethToUsd = uint256(getLatestPrice());
    uint256 tokens = _weiAmount.mul(ethToUsd) / (0.001 * 10**26);

    return tokens;
  }
  
  function _getUSDAmount(uint256 _weiAmount) public view returns (uint256) {
    uint256 ethToUsd = uint256(getLatestPrice());
    uint256 minBuyValue = _weiAmount.mul(ethToUsd) / ( 10**26);

    return minBuyValue;
  }
    
  function stopICO() onlyOwner public {
    running=false;
  }
  function startICO() onlyOwner public {
    running=true;
  }


  function _forwardFunds() internal  {
    wallet.transfer(msg.value);
  }
}