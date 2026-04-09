// Copyright 2025, NoFeeSwap LLC - All rights reserved.
pragma solidity ^0.8.28;

import {ISentinel} from "@core/interfaces/ISentinel.sol";
import {INofeeswap} from "@core/interfaces/INofeeswap.sol";
import {
  getMsgSenderFromCalldata,
  getTag0FromCalldata,
  getTag1FromCalldata,
  getPoolGrowthPortionFromCalldata,
  getPoolIdFromCalldata,
  getStaticParamsStoragePointerExtensionFromCalldata
} from "@core/hooks/HookCalldata.sol";
import {getStaticParamsStorageAddress} from "@core/utilities/Storage.sol";
import {
  TagsOutOfOrder,
  InvalidGrowthPortion
} from "@core/utilities/Errors.sol";
import {IERC20} from "@openzeppelin/interfaces/IERC20.sol";
import {Tag} from "@core/utilities/Tag.sol";
import {
  _poolGrowthPortion_,
  _staticParams_
} from "@core/utilities/Memory.sol";
import {X47, zeroX47, oneX47, maxX47} from "@core/utilities/X47.sol";

contract Sentinel is ISentinel {
  /// @notice Nofeeswap contract address which calls to authorize functions.
  INofeeswap public immutable nofeeswap;

  /// @notice The address which is exempt from costs.
  address public immutable exempt;

  /// @notice ERC-20 address of the token to be claimed to authorize pool 
  /// initialization and modification of pool growth portion.
  IERC20 public immutable token;

  /// @notice The admin of this contract which sets costs for initialization
  /// and modification of pool growth portion.
  address public admin;

  /// @notice The amount of tokens to be claimed to authorize pool
  /// initialization.
  uint256 public initializationCost;

  /// @notice The amount of tokens to be claimed to authorize increasing a pool 
  /// growth portion or setting an initial non-zero value.
  uint256 public growthPortionCost;

  /// @notice '(maxPoolGrowthPortion << 48) + protocolGrowthPortion' which can
  /// be set by admin for each specific pair.
  mapping (Tag => mapping (Tag => uint256)) public growthPortions;

  constructor(
    INofeeswap _nofeeswap,
    address _exempt,
    IERC20 _token,
    uint256 _initializationCost,
    uint256 _growthPortionCost,
    address _admin
  ) {
    nofeeswap = _nofeeswap;
    exempt = _exempt;
    token = _token;
    initializationCost = _initializationCost;
    growthPortionCost = _growthPortionCost;
    admin = _admin;
  }

  /// @notice Prevents any address other than 'admin' to call this function.
  modifier onlyByAdmin() {
    address _admin = admin;
    require(msg.sender == _admin, OnlyByAdmin(msg.sender, _admin));
    _;
  }

  /// @notice Sets a new admin for this contract. Should be run by the current
  /// admin only.
  /// @param _admin Address of the new admin.
  function setAdmin(address _admin) external onlyByAdmin {
    emit NewAdmin(admin, _admin);
    admin = _admin;
  }

  /// @notice Sets new value for 'maxPoolGrowthPortion' and 
  /// 'protocolGrowthPortion' for each of the given pair of tags. Should be run
  /// by the admin only.
  /// @param tag0 An array of arithmetically smaller tags.
  /// @param tag1 An array of arithmetically larger tags.
  /// @param maxPoolGrowthPortion Given values for 'maxPoolGrowthPortion'.
  /// @param protocolGrowthPortion Given values for 'protocolGrowthPortion'.
  function setGrowthPortions(
    Tag[] calldata tag0,
    Tag[] calldata tag1,
    X47[] calldata maxPoolGrowthPortion,
    X47[] calldata protocolGrowthPortion
  ) external onlyByAdmin {
    require(
      tag0.length == tag1.length,
      UnequalLengths(tag0.length, tag1.length)
    );
    require(
      tag0.length == maxPoolGrowthPortion.length,
      UnequalLengths(tag0.length, maxPoolGrowthPortion.length)
    );
    require(
      tag0.length == protocolGrowthPortion.length,
      UnequalLengths(tag0.length, protocolGrowthPortion.length)
    );

    unchecked {
      for (uint256 k = 0; k < tag0.length; ++k) {
        require(tag0[k] < tag1[k], TagsOutOfOrder(tag0[k], tag1[k]));

        // 'maxX47' indicates 'zeroX47'. Any amount greater than 'oneX47'
        // indicates the protocol slot's default value.
        X47 _maxPoolGrowthPortion = maxPoolGrowthPortion[k];
        if (_maxPoolGrowthPortion == zeroX47) {
          _maxPoolGrowthPortion = maxX47;
        } else if (_maxPoolGrowthPortion > oneX47) {
          _maxPoolGrowthPortion = zeroX47;
        }

        // 'maxX47' indicates 'zeroX47'. Any amount greater than 'oneX47'
        // indicates the protocol slot's default value.
        X47 _protocolGrowthPortion = protocolGrowthPortion[k];
        if (_protocolGrowthPortion == zeroX47) {
          _protocolGrowthPortion = maxX47;
        } else if (_protocolGrowthPortion > oneX47) {
          _protocolGrowthPortion = zeroX47;
        }

        uint256 _growthPortions;
        assembly ("memory-safe") {
          _growthPortions := or(
            shl(48, _maxPoolGrowthPortion),
            _protocolGrowthPortion
          )
        }

        growthPortions[tag0[k]][tag1[k]] = _growthPortions;

        emit NewSentinelGrowthPortions(
          tag0[k],
          tag1[k],
          maxPoolGrowthPortion[k],
          protocolGrowthPortion[k]
        );
      }
    }
  }

  /// @notice Sets a new value for the amount of tokens to be claimed to
  /// authorize pool initialization. Should be run by the admin only.
  /// @param _initializationCost The new value for initialization cost.
  function setInitializationCost(
    uint256 _initializationCost
  ) external onlyByAdmin {
    uint256 initializationCost_ = initializationCost;
    initializationCost = _initializationCost;
    emit NewInitializationCost(initializationCost_, _initializationCost);
  }

  /// @notice Sets a new value for the amount of tokens to be claimed to
  /// authorize increasing a pool growth portion or setting an initial non-zero
  /// value. Should be run by the admin only.
  /// @param _growthPortionCost The new cost value.
  function setGrowthPortionCost(
    uint256 _growthPortionCost
  ) external onlyByAdmin {
    uint256 growthPortionCost_ = growthPortionCost;
    growthPortionCost = _growthPortionCost;
    emit NewGrowthPortionCost(growthPortionCost_, _growthPortionCost);
  }

  modifier onlyNofeeswap() {
    require(INofeeswap(msg.sender) == nofeeswap, OnlyByNofeeswap(msg.sender));
    _;
  }

  /// @inheritdoc ISentinel
  function getGrowthPortions(
    bytes calldata sentinelInput
  ) external view override returns (
    X47 maxPoolGrowthPortion,
    X47 protocolGrowthPortion
  ) {
    uint256 _growthPortions = 
      growthPortions[getTag0FromCalldata()][getTag1FromCalldata()];
    assembly ("memory-safe") {
      protocolGrowthPortion := and(_growthPortions, 0xFFFFFFFFFFFF)
      maxPoolGrowthPortion := and(shr(48, _growthPortions), 0xFFFFFFFFFFFF)
    }

    // 'maxX47' indicates 'zeroX47'. 'zeroX47' indicates protocol slot's
    // default value.
    if (maxPoolGrowthPortion == maxX47) {
      maxPoolGrowthPortion = zeroX47;
    } else if (maxPoolGrowthPortion == zeroX47) {
      maxPoolGrowthPortion = maxX47;
    }

    // 'maxX47' indicates 'zeroX47'. 'zeroX47' indicates protocol slot's
    // default value.
    if (protocolGrowthPortion == maxX47) {
      protocolGrowthPortion = zeroX47;
    } else if (protocolGrowthPortion == zeroX47) {
      protocolGrowthPortion = maxX47;
    }
  }

  /// @inheritdoc ISentinel
  function authorizeInitialization(
    bytes calldata sentinelInput
  ) external override onlyNofeeswap returns (bytes4) {
    if (getMsgSenderFromCalldata() == exempt) {
      return ISentinel.authorizeInitialization.selector;
    }
    token.transferFrom(getMsgSenderFromCalldata(), admin, initializationCost);
    return ISentinel.authorizeInitialization.selector;
  }

  /// @inheritdoc ISentinel
  function authorizeModificationOfPoolGrowthPortion(
    bytes calldata sentinelInput
  ) external override onlyNofeeswap returns (bytes4) {
    if (getMsgSenderFromCalldata() == exempt) {
      return ISentinel.authorizeModificationOfPoolGrowthPortion.selector;
    }

    X47 _poolGrowthPortion = getPoolGrowthPortionFromCalldata();

    address storageAddress = getStaticParamsStorageAddress(
      msg.sender,
      getPoolIdFromCalldata(),
      getStaticParamsStoragePointerExtensionFromCalldata()
    );

    X47 poolGrowthPortion_;
    assembly {
      extcodecopy(
        storageAddress,
        0,
        add(1, sub(_poolGrowthPortion_, _staticParams_)),
        6
      )
      poolGrowthPortion_ := shr(208, mload(0))
    }

    if (_poolGrowthPortion > poolGrowthPortion_) {
      token.transferFrom(getMsgSenderFromCalldata(), admin, growthPortionCost);
    }

    return ISentinel.authorizeModificationOfPoolGrowthPortion.selector;
  }

  /// @notice Thrown when any account other than admin attempts to access a
  /// functionality which is reserved for the admin.
  error OnlyByAdmin(address attemptingAddress, address adminAddress);

  /// @notice Thrown when the length of two input arrays that are supposed to be 
  /// equal differ from each other.
  error UnequalLengths(uint256 length0, uint256 length1);

  /// @notice Thrown when attempting to access functionalities that are only
  /// available to Nofeeswap contract.
  error OnlyByNofeeswap(address attemptingAddress);

  /// @notice Emitted when a new admin is assigned.
  event NewAdmin(
    address indexed oldAdmin,
    address indexed newAdmin
  );

  /// @notice Emitted when a new initialization cost is set.
  event NewInitializationCost(
    uint256 oldInitializationCost,
    uint256 newInitializationCost
  );

  /// @notice Emitted when a new growth portion cost is set.
  event NewGrowthPortionCost(
    uint256 oldGrowthPortionCost,
    uint256 newGrowthPortionCost
  );

  /// @notice Emitted when new growth portions are set by the sentinel contract.
  event NewSentinelGrowthPortions(
    Tag indexed tag0,
    Tag indexed tag1,
    X47 newMaxPoolGrowthPortion,
    X47 newProtocolGrowthPortion
  );
}