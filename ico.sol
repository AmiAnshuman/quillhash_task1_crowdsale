


pragma solidity ^0.6.0;



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


  ERC20 public token;  // address of ERC20 token contract


  address payable public  wallet;  // amount of ETH will be transferred to this wallet

  uint256 public usdRaised; // amount of USD raised
  
  AggregatorV3Interface internal priceFeed; //oracle contract ot find latest price of ETH->USD

  mapping(address => uint256) public contributions; //contributions of easch whitelited customer
  mapping(address => bool) public whitelist; // list of whitelisted customer
  
  uint256 public openingTime;
  uint256 public closingTime;
  
  bool public running=false; // need to start the ICO first


 
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  
  modifier isWhitelisted(address _beneficiary) {
    require(whitelist[_beneficiary], "Only whitelisted customers can participate in ICO");
    _;
  }
  

  modifier onlyWhileOpen {
    require(now >= openingTime && now <= closingTime, "ICO openingTime and closingTime check");
    _;
  }
  
  modifier onlyWhileRunning {
    require(running==true, "Checking whether ICO is running or not");
    _;
  }
  
    constructor (address _token, address payable _wallet) public {
        
        require(_token!=address(0) && _wallet!=address(0), "Wallet and token address cannot be zero");
        token= ERC20(_token);
        wallet=_wallet;
        openingTime=now;
        closingTime=now+62 days;
        priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
  }
  
  fallback () external payable {
    buyTokens(msg.sender);
  }

  function addToWhitelist(address _beneficiary) external onlyOwner {
    whitelist[_beneficiary] = true;
  }

  
  function addManyToWhitelist(address[] memory _beneficiaries) external onlyOwner {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      whitelist[_beneficiaries[i]] = true;
    }
  }


  function removeFromWhitelist(address _beneficiary) external onlyOwner {
    whitelist[_beneficiary] = false;
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
    
    require(token.balanceOf(address(this))>=tokens, "Number of tokens available in the contract or not");

    // update how much usd has been raised in ICO
    usdRaised = usdRaised.add(BuyValue);
    
    //bonus token the user will get
    uint256 bonus=_bonusTransfer(tokens);
    
    //total tokens transferred to the user
    _processPurchase(_beneficiary, tokens.add(bonus));
    
    emit TokenPurchase(
      address(this),
      _beneficiary,
      weiAmount,
      tokens.add(bonus)
    );
    
    // user contributions updated
    _updatePurchasingState(_beneficiary, BuyValue);
    
    // ETh transferred from user to the token owner
    _forwardFunds();
  }



  function _preValidatePurchase(address _beneficiary, uint256 usdAmount) internal {
    require(_beneficiary != address(0), "beneficiary address cannot be zero");
    require(usdAmount>=500, "Minimum value to buy is 500 per investor");
    require(contributions[_beneficiary].add(usdAmount) <= 5000000, "Maximum value to buy is 5000000 per investor");
  }


// function to allocate the bonus token to the user depending on the time of putrchase
  function _bonusTransfer( uint256 _tokenAmount) internal returns(uint256) {
      
    uint256 bonusToken;
    if(now <= openingTime+15 days && now >= openingTime)
    {
        bonusToken=_tokenAmount/4;

    }
    
    else if(now <= openingTime+30 days && now > openingTime+15 days)
    {
        bonusToken=_tokenAmount/5;

    }
    else if(now <= openingTime+38 days && now >openingTime+30 days)
    {
        bonusToken=(_tokenAmount*15/100);

    }
    else if(now <= openingTime+46 days && now >openingTime+38 days)
    {
        bonusToken=_tokenAmount/10;

    }
    else if(now <= openingTime+54 days && now >openingTime+46 days)
    {
        bonusToken=_tokenAmount/20;

    }
    return bonusToken;
  }

// function to transfer the token from contract to the user 
  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    token.transfer(_beneficiary, _tokenAmount);
  }



  function _updatePurchasingState(address _beneficiary, uint256 usdAmount) internal {
    contributions[_beneficiary] = contributions[_beneficiary].add(usdAmount);
  }

    
    // function to convert eth to number of tokens

  function _getTokenAmount(uint256 _weiAmount) public view returns (uint256) {
    uint256 ethToUsd = uint256(getLatestPrice());
    uint256 tokens = _weiAmount.mul(ethToUsd) / (0.001 * 10**8);

    return tokens;
  }
  
  // function to convert eth to usd
  
  function _getUSDAmount(uint256 _weiAmount) public view returns (uint256) {
    uint256 ethToUsd = uint256(getLatestPrice());
    uint256 minBuyValue = _weiAmount.mul(ethToUsd) / ( 10**26);

    return minBuyValue;
  }
    
    
    // function to stopICO
  function stopICO() onlyOwner public {
    running=false;
  }
  
  //function to startICO
  function startICO() onlyOwner public {
    running=true;
  }

    // function to transfer the fund from token buyer to owner address
  function _forwardFunds() internal  {
    wallet.transfer(msg.value);
  }
  
  
    // Call when ICO contract need to be removed  
  function self_Destruct () public payable onlyOwner {
      uint256 _tokenAmount=token.balanceOf(address(this));
      token.transfer(wallet, _tokenAmount);
      selfdestruct( payable (address(this)));
    }
}