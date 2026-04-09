// Credit to: https://github.com/compound-finance/compound-protocol/blob/
// a3214f67b73310d547e00fc578e8355911c9d376/contracts/Governance/Comp.sol
pragma solidity ^0.8.10;

import {INofee} from "./interfaces/INofee.sol";

contract Nofee is INofee {
    /// @inheritdoc INofee
    string public constant name = "Nofeeswap";

    /// @inheritdoc INofee
    string public constant symbol = "NOFEE";

    /// @inheritdoc INofee
    uint8 public constant decimals = 18;

    /// @inheritdoc INofee
    uint public totalSupply = 10000000000e18; // 10 billion Nofee

    /// @inheritdoc INofee
    address public minter;

    /// @inheritdoc INofee
    uint public mintingAllowedAfter;

    /// @inheritdoc INofee
    uint32 public constant minimumTimeBetweenMints = 1 days * 365;

    /// @inheritdoc INofee
    uint8 public constant mintCap = 2;

    /// @notice Allowance amounts on behalf of others
    mapping (address => mapping (address => uint96)) internal allowances;

    /// @notice Official record of token balances for each account
    mapping (address => uint96) internal balances;

    /// @inheritdoc INofee
    mapping (address => address) public delegates;

    /// @inheritdoc INofee
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    /// @inheritdoc INofee
    mapping (address => uint32) public numCheckpoints;

    /// @inheritdoc INofee
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @inheritdoc INofee
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @inheritdoc INofee
    bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /// @inheritdoc INofee
    mapping (address => uint) public nonces;

    /**
     * @notice Construct a new Nofee contract
     * @param account The initial account to grant all the tokens
     * @param minter_ The account with minting ability
     * @param mintingAllowedAfter_ The timestamp after which minting may occur
     */
    constructor(address account, address minter_, uint mintingAllowedAfter_) {
        require(mintingAllowedAfter_ >= block.timestamp, "Nofee::constructor: minting can only begin after deployment");

        balances[account] = uint96(totalSupply);
        emit Transfer(address(0), account, totalSupply);
        minter = minter_;
        emit MinterChanged(address(0), minter);
        mintingAllowedAfter = mintingAllowedAfter_;
    }

    /// @inheritdoc INofee
    function setMinter(address minter_) external {
        require(msg.sender == minter, "Nofee::setMinter: only the minter can change the minter address");
        emit MinterChanged(minter, minter_);
        minter = minter_;
    }

    /// @inheritdoc INofee
    function mint(address dst, uint rawAmount) external {
        require(msg.sender == minter, "Nofee::mint: only the minter can mint");
        require(block.timestamp >= mintingAllowedAfter, "Nofee::mint: minting not allowed yet");
        require(dst != address(0), "Nofee::mint: cannot transfer to the zero address");

        // record the mint
        mintingAllowedAfter = block.timestamp + minimumTimeBetweenMints;

        // mint the amount
        uint96 amount = safe96(rawAmount, "Nofee::mint: amount exceeds 96 bits");
        require(amount <= (uint128(totalSupply) * mintCap) / 100, "Nofee::mint: exceeded mint cap");
        totalSupply = safe96(totalSupply + amount, "Nofee::mint: totalSupply exceeds 96 bits");

        // transfer the amount to the recipient
        balances[dst] = add96(balances[dst], amount, "Nofee::mint: transfer amount overflows");
        emit Transfer(address(0), dst, amount);

        // move delegates
        _moveDelegates(address(0), delegates[dst], amount);
    }

    /// @inheritdoc INofee
    function allowance(address account, address spender) external view returns (uint) {
        return allowances[account][spender];
    }

    /// @inheritdoc INofee
    function approve(address spender, uint rawAmount) external returns (bool) {
        uint96 amount;
        if (rawAmount == type(uint).max) {
            amount = type(uint96).max;
        } else {
            amount = safe96(rawAmount, "Nofee::approve: amount exceeds 96 bits");
        }

        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /// @inheritdoc INofee
    function permit(address owner, address spender, uint rawAmount, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        address signatory = ecrecover(keccak256(abi.encodePacked(
          "\x19\x01",
          keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this))),
          keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, rawAmount, nonces[owner]++, deadline))
        )), v, r, s);
        require(signatory != address(0), "Nofee::permit: invalid signature");
        require(signatory == owner, "Nofee::permit: unauthorized");
        require(block.timestamp <= deadline, "Nofee::permit: signature expired");

        uint96 amount = (rawAmount == type(uint).max) ? type(uint96).max : safe96(rawAmount, "Nofee::permit: amount exceeds 96 bits");

        allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    /// @inheritdoc INofee
    function balanceOf(address account) external view returns (uint) {
        return balances[account];
    }

    /// @inheritdoc INofee
    function transfer(address dst, uint rawAmount) external returns (bool) {
        uint96 amount = safe96(rawAmount, "Nofee::transfer: amount exceeds 96 bits");
        _transferTokens(msg.sender, dst, amount);
        return true;
    }

    /// @inheritdoc INofee
    function transferFrom(address src, address dst, uint rawAmount) external returns (bool) {
        address spender = msg.sender;
        uint96 spenderAllowance = allowances[src][spender];
        uint96 amount = safe96(rawAmount, "Nofee::approve: amount exceeds 96 bits");

        if (spender != src && spenderAllowance != type(uint96).max) {
            uint96 newAllowance = sub96(spenderAllowance, amount, "Nofee::transferFrom: transfer amount exceeds spender allowance");
            allowances[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }

    /// @inheritdoc INofee
    function delegate(address delegatee) public {
        return _delegate(msg.sender, delegatee);
    }

    /// @inheritdoc INofee
    function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) public {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "Nofee::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "Nofee::delegateBySig: invalid nonce");
        require(block.timestamp <= expiry, "Nofee::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    /// @inheritdoc INofee
    function getCurrentVotes(address account) external view returns (uint96) {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /// @inheritdoc INofee
    function getPriorVotes(address account, uint blockNumber) public view returns (uint96) {
        require(blockNumber < block.number, "Nofee::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee) internal {
        require(delegatee != address(0), "Nofee::_delegate: cannot delegate to the zero address");

        address currentDelegate = delegates[delegator];
        uint96 delegatorBalance = balances[delegator];
        delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _transferTokens(address src, address dst, uint96 amount) internal {
        require(src != address(0), "Nofee::_transferTokens: cannot transfer from the zero address");
        require(dst != address(0), "Nofee::_transferTokens: cannot transfer to the zero address");

        balances[src] = sub96(balances[src], amount, "Nofee::_transferTokens: transfer amount exceeds balance");
        balances[dst] = add96(balances[dst], amount, "Nofee::_transferTokens: transfer amount overflows");
        emit Transfer(src, dst, amount);

        _moveDelegates(delegates[src], delegates[dst], amount);
    }

    function _moveDelegates(address srcRep, address dstRep, uint96 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint96 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint96 srcRepNew = sub96(srcRepOld, amount, "Nofee::_moveVotes: vote amount underflows");
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint96 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint96 dstRepNew = add96(dstRepOld, amount, "Nofee::_moveVotes: vote amount overflows");
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(address delegatee, uint32 nCheckpoints, uint96 oldVotes, uint96 newVotes) internal {
      uint32 blockNumber = safe32(block.number, "Nofee::_writeCheckpoint: block number exceeds 32 bits");

      if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
          checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
      } else {
          checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
          numCheckpoints[delegatee] = nCheckpoints + 1;
      }

      emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function safe96(uint n, string memory errorMessage) internal pure returns (uint96) {
        require(n < 2**96, errorMessage);
        return uint96(n);
    }

    function add96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        uint96 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function getChainId() internal view returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}