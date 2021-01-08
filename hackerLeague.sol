// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.0.0/contracts/token/ERC20/ERC20.sol";

//用户推荐关系、算力购买、HE-3 代币释放和用户收益提取记录为去中心化
contract HackerLeague {
    // 用户推荐关系
    // 上级
    mapping(address => address) private mySuperior;
    // 是否已有上级
    mapping(address => bool) private isHasSuperior;

    // 算力购买
    // 是否已经购买过了
    mapping(address => bool) private isBuy;
    // 算力购买情况
    mapping(address => uint) hashRate;

    // 保存直接上级事件
    event LogSaveSuperior(address owner,address superior);
    // 算力购买情况事件
    event LogBuyHashRate(address owner, uint hashRate);
    // 用户收益提取记录事件
    event LogWithdraw(address owner, uint reward);


    // 好友接收邀请后并购买了算力后调用的合约方法
    function saveSuperior(address _superior) public {
        // 不能已有上级
        require(!isHasSuperior[msg.sender],"only one superior");
        // 上级地址不为 0
        require(_superior != address(0), "Invalid superior");
        // 上级需要购买过算力
        require(isBuy[_superior], "superior need has hashRate");

        // 需要当前地址已经购买算力
        require(isBuy[msg.sender],"Not yet buy hashRate");
        // 保存上级
        mySuperior[msg.sender] = _superior;

        // 触发事件
        emit LogSaveSuperior(msg.sender, _superior);
    }

    // 用户购买算力：多少 T
    function buyHashRate(uint _hashRate) public {
        // 单次购买下限 1 T
        require(_hashRate >= 1, "Need buy 1 T least");
        //
        require((hashRate[msg.sender] + _hashRate) >= hashRate[msg.sender]);
        // 更新算力购买情况
        hashRate[msg.sender] += _hashRate;
        // 更新
        isBuy[msg.sender] = true;

        // 触发事件
        emit LogBuyHashRate(msg.sender, _hashRate);
    }

    // HE-3 代币释放
    // ERC20 合约单独操作


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