// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract Registration {
    
    using SafeMath for uint256;
    IERC20 public token;

    uint256 LOCK_AMOUNT = 100;
    uint256 FEE_UNIT = 1;
    uint256 NAME_LIMIT = LOCK_AMOUNT.div(FEE_UNIT);
    uint256 EXPIRE_PERIOD = 3 days;

    struct Reg {
        string name;
        uint256 regTime;
    }

    mapping(address=>Reg) public regs;

    uint256 counter;

    constructor (address _address) {
        token = IERC20(_address);
        LOCK_AMOUNT = LOCK_AMOUNT.mul(10 ** token.decimal());
    }
    
    function add(string memory _name, uint256 _counter) external {
        require(counter == _counter, "This transaction could be frontrunning");
        require(bytes(_name).length <= NAME_LIMIT, "too long.");
        require(regs[msg.sender].name == '', "Already registered. You can renew existing name");
        require(token.balanceOf(msg.sender) >= LOCK_AMOUNT, "Insufficient funds");
        regs[msg.sender].name = _name;
        regs[msg.sender].regTime = block.timestamp;
        counter = counter.add(1);

        token.transferFrom(msg.sender, address(this), LOCK_AMOUNT);
    }

    function releaseFund(address _address) external {
        require(regs[_address].name != '', "Already released fund");
        require(regs[msg.sender].regTime.add(EXPIRE_PERIOD) < block.timestamp, "You can't release");
        uint256 fee = bytes(_name).length.mul(FEE_UNIT).mul(10 ** token.decimal());
        regs[_address].name = '';
        counter = counter.add(1);
        token.transfer(_address, LOCK_AMOUNT.sub(fee));
    }
    
    function renew() external {
        require(regs[msg.sender].regTime.add(EXPIRE_PERIOD) >= block.timestamp, "Already Expired");
        regs[msg.sender].regTime = block.timestamp;
        counter = counter.add(1);
    }
}
