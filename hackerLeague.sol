// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.0.0/contracts/token/ERC20/ERC20.sol";


//用户推荐关系、算力购买、HE-3 代币释放和用户收益提取记录为去中心化
contract HackerLeague {
    address public owner;
    //
    struct user {
        address superior;
        uint256 hashRate;
    }
    mapping(address => user) public users;

    // 算力购买情况事件
    event LogBuyHashRate(address owner, uint hashRate, address superior);
    // 用户收益提取记录事件
    event LogWithdraw(address owner, uint reward);

    constructor() public {
        owner = msg.sender;
    }

    /**
     * Requirements:
     *
     * - `_token` HE-1 或者 HE-3 的合约地址
     * - `_tokenAmount` token 数量
     * - `_price` token 与 usdt 对应的价格，考虑小数点，需要协定 1 = 10000，0.03 = 300
     * - `_superior` 直接上级
     */
    function buyHashRate(ERC20 _token,uint _tokenAmount, uint _price, address _superior) public {
        uint totalUsdt = _tokenAmount / _price;
        // 10 USDT = 1T
        // 计算当前能买多少 T
        uint _hashRate = totalUsdt / 10;
        // 单次购买下限 1 T
        require(_hashRate >= 1, "Need buy 1T least");
        require(
            _token.allowance(msg.sender, address(this)) >= _tokenAmount,
            "Token allowance too low"
        );
        bool sent = _token.transferFrom(msg.sender, owner, _tokenAmount);
        require(sent, "Token transfer failed");

        if (_superior == address(0)) {
            // 已有上级，继续购买算力
            require(users[msg.sender].superior != address(0), "no superior");

            users[msg.sender].hashRate += _hashRate;
        } else {
            // 第一次购买算力
            users[msg.sender].superior = _superior;
            users[msg.sender].hashRate = _hashRate;
        }

        // 触发事件
        emit LogBuyHashRate(msg.sender, _hashRate, _superior);
    }

    // 用户收益提取记录
    function withdraw(ERC20 _token,address sender,address recipient, uint _reward) public {
        require(
            _token.allowance(sender, address(this)) >= _reward,
            "Token allowance too low"
        );
        bool sent = _token.transferFrom(sender, recipient, _reward);
        require(sent, "Token transfer failed");

        // 触发事件
        emit LogWithdraw(msg.sender, _reward);
    }
}