// SPDX-License-Identifier: MIT

//0x20890D6288f2D510785B81A30fDE866b8fb64a9e
//Deployed on Kovan
//_nbBlocks = 10

pragma solidity ^0.8.0;

// library import
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol";
import "./Ownable.sol";

/// @title King Of The Hill Game
/// @author D.Savel
/// @notice You can use this contract for basics rules implementation for King Of The Hill Game

contract KingOfTheHill is Ownable{
    // library usage
    using Address for address payable;

    // State variables
    mapping(address => uint256) private _balances;
    uint256 immutable private _nbBlocks;
    address private _potOwner;
    uint256 private _profitPercentage = 10;
    uint256 private _seedPercentage = 10;
    uint256 private _totalProfit;
    uint256 private _blockStart;
    uint256 private _currentPot;
    bool private _isNewGame;

    // Events
    event BoughtUpPot(address indexed sender, uint256 currentPot, uint256 _blockStart);
    event WithdrewPot(address indexed recipient, uint256 amount, uint256 currentPot);
    event NewGame (bool isnewgame, uint256 blockNumber);


    // constructor
    
     /// @notice For deploiement minimum value is 1 finney and owner address is required 
    constructor(address owner_, uint256 nbBlocks_) Ownable(owner_) payable{
         require(nbBlocks_ > 0 && nbBlocks_ <= 100, "KingOfTheHill: Invalid number of blocks");
         require(msg.value >= 1e15, "KingOfTheHill: At least 1 finney deposit is necessary to initialize smartcontract");
        _nbBlocks = nbBlocks_;
        _potOwner = owner();
        _blockStart = 0;
        payable(this);
        _currentPot = address(this).balance;
    }
    
 // modifiers
    /// @dev Le modifier onlyOwner a été défini dans le smart contract Ownable
    modifier samePotOwner() {
        require(msg.sender != _potOwner, "KingOfTheHill : You are already the current pot owner.");
        _;
    }

    // Functions declarations below
    receive() external payable{
    }
    
    /// @notice New player can buy up the pot with paying twice the current pot. If amount transaction is bigger than twice current pot the excedent is return to the new player.
    /// @dev buyUpPot use isNewGame function to implement new game before buying up if condition isNewGame is true
    function buyUpPot() public payable samePotOwner {
        isNewGame();
        require(msg.value >= 2 * _currentPot, "KingOfTheHill: Deposit amount must be equal 2x pot Amount to become new pot owner");
        _potOwner = msg.sender;
        if (msg.value > _currentPot * 2) {
            payable(msg.sender).sendValue(msg.value - _currentPot * 2);
        }
        /// @dev implements new block start and new pot amount after a new pot owner
        _blockStart = block.number;
        _currentPot += _currentPot * 2;
        emit BoughtUpPot(msg.sender, _currentPot, _blockStart);
    }
    
   function getPotAmount() public view returns (uint256) {
        return address(this).balance;
    }
    
   function getPotOwner() public view returns (address) {
        return _potOwner;
    }
    
    function getTotalProfit() public view returns(uint256) {
         /// @return cumulate profit for owner since contract deploiement
        return _totalProfit;
    }
    
    /// @notice In case of pot owner victory, pay to pot owner his gain, profit to owner and redistribute seed for new pot amount.
     /// @dev withdrawPot is use in isNewGame function if isNewGame is true
    function withdrawPot(uint256 currentPot_) private{
        uint256 fees = 0;
        uint256 seed  = (currentPot_ * _seedPercentage) / 100;
        if (msg.sender != owner()) {
           fees =  _calculateFees(currentPot_, _profitPercentage);
        }
        uint256 newAmount = currentPot_- fees - seed;
        _totalProfit += fees;
        payable(_potOwner).sendValue(newAmount);
        payable(owner()).sendValue(fees);
        _potOwner = address(0);
        _currentPot = (_currentPot * _seedPercentage) /100;
        emit WithdrewPot(_potOwner, newAmount, _currentPot);
    }
    
    /// @notice Evaluate if nbBlocks past for pot owner victory and start a new game in this case
    /// @dev isNewGame use withdrawPot function for withdrawing pot amount
    function isNewGame() private{
       if (_blockStart !=0 && block.number - _blockStart >= _nbBlocks) {
            _isNewGame = true;
            withdrawPot(_currentPot);
        } else {
             _isNewGame = false;
        }
        emit NewGame(_isNewGame, block.number);
    }
   
    function _calculateFees(uint256 amount, uint256 taxPercentage_) private pure returns (uint256) {
         /// @return fees amount for retributing owner
        return (amount * taxPercentage_) / 100;
    }
  }
