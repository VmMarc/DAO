//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./DAOToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract DAO is Ownable {
    DAOToken private _token;
    using Counters for Counters.Counter;

    enum Vote {
        Yes,
        No
    }
    enum Status {
        Running,
        Approved,
        Rejected
    }

    struct Proposal {
        Status status;
        address author;
        uint256 createdAt;
        uint256 nbYes;
        uint256 nbNo;
        string proposition;
    }

    uint256 private _supplyInStock;
    uint256 private _rate;
    uint256 public constant TIME_LIMIT = 3 minutes;

    Counters.Counter private _id;
    mapping(uint256 => Proposal) private _proposals;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(uint256 => bool)) private _hasVote;

    event TokenBought(address indexed sender, uint256 amount);
    event TokenWithdrew(address indexed sender, uint256 amount);
    event ProposalEnded(uint256 id, string status, uint256 epoch);
    event Voted(address indexed sender, uint256 amount, uint256 power);

    constructor(address token) {
        _token = DAOToken(token);
        _supplyInStock = _token.balanceOf(owner());
        _rate = 10**3;
    }

    receive() external payable {
        require(msg.value != 0, "DAO: Cannot buy 0 Token");
        uint256 tokenAmount = msg.value * _rate;
        require(_supplyInStock >= tokenAmount, "DAO: there is not enought token");
        _token.transferFrom(owner(), msg.sender, tokenAmount);
        _balances[msg.sender] += tokenAmount;
        emit TokenBought(msg.sender, tokenAmount);
    }

    function buyTokens(uint256 amount) public payable {
        require(amount != 0, "DAO: Cannot buy 0 Token");
        uint256 tokenAmount = amount * _rate;
        require(_supplyInStock >= tokenAmount, "DAO: there is not enought token");
        _token.transferFrom(owner(), address(this), tokenAmount);
        _balances[msg.sender] += tokenAmount;
        emit TokenBought(msg.sender, tokenAmount);
    }

    function createProposal(string memory proposition) public returns (uint256) {
        _id.increment();
        uint256 id = _id.current();
        _proposals[id] = Proposal({
            status: Status.Running,
            author: msg.sender,
            createdAt: block.timestamp,
            nbYes: 0,
            nbNo: 0,
            proposition: proposition
        });
        return id;
    }

    function vote(
        uint256 id,
        Vote vote_,
        uint256 tokenAmount
    ) public {
        require(_balances[msg.sender] >= 1, "DAO: In order to vote you need to have at least 1 Token");
        require(_hasVote[msg.sender][id] == false, "DAO: Already voted");
        require(_proposals[id].status == Status.Running, "DAO: Not a running proposal");

        if (block.timestamp > _proposals[id].createdAt + TIME_LIMIT) {
            if (_proposals[id].nbYes > _proposals[id].nbNo) {
                _proposals[id].status = Status.Approved;
                emit ProposalEnded(id, "Approved", block.timestamp);
            } else {
                _proposals[id].status = Status.Rejected;
                emit ProposalEnded(id, "Rejected", block.timestamp);
            }
        } else {
            require(_balances[msg.sender] >= 1, "DAO: Vote costs at least 1 Token");
            if (vote_ == Vote.Yes) {
                _proposals[id].nbYes += 1 * _power(tokenAmount);
            } else {
                _proposals[id].nbNo += 1 * _power(tokenAmount);
            }
            _balances[msg.sender] -= tokenAmount;
            _hasVote[msg.sender][id] = true;
            emit Voted(msg.sender, tokenAmount, _power(tokenAmount));
        }
    }

    function withdraw() public payable {
        require(_balances[msg.sender] != 0, "DAO: You do not have Tokens");
        uint256 totalAmount = _balances[msg.sender];
        _balances[msg.sender] = 0;
        _token.transfer(msg.sender, totalAmount);
        emit TokenWithdrew(msg.sender, totalAmount);
    }

    function proposalById(uint256 id) public view returns (Proposal memory) {
        return _proposals[id];
    }

    function hasVote(address account, uint256 id) public view returns (bool) {
        return _hasVote[account][id];
    }

    function _power(uint256 tokenAmount) internal pure returns (uint256) {
        uint256 nb;
        if (tokenAmount >= 1 && tokenAmount <= 25) {
            nb = 1;
        } else if (tokenAmount > 25 && tokenAmount <= 50) {
            nb = 2;
        } else if (tokenAmount > 50 && tokenAmount <= 100) {
            nb = 3;
        } else {
            nb = 4;
        }
        return nb;
    }

    function checkPower(uint256 tokenAmount) public view returns (uint256) {
        return _power(tokenAmount);
    }
}
