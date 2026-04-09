# Copyright 2025, NoFeeSwap LLC - All rights reserved.
variables = [
    ['freeMemoryPointer', 256, 'uint256', 'getter', 'setter'],
    ['blank', 256],
    ['hookSelector', 32, 'uint32', 'setter'],
    ['hookInputHeader', 256, 'uint256', 'setter'],
    ['hookInputByteCount', 256, 'uint256', 'getter', 'setter'],
    ['msgSender', 160, 'address', 'setter'],
    ['poolId', 256, 'uint256', 'getter', 'setter'],
    ['swapInput', 0],
    ['crossThreshold', 128, 'uint256', 'getter', 'setter'],
    ['amountSpecified', 256, 'X127', 'getter', 'setter'],
    ['logPriceLimit', 256, 'X59', 'getter', 'setter'],
    ['logPriceLimitOffsetted', 64, 'X59', 'getter', 'setter'],
    ['swapParams', 0],
    ['zeroForOne', 8, 'bool', 'getter', 'setter'],
    ['exactInput', 8, 'bool', 'getter', 'setter'],
    ['integralLimit', 216, 'X216', 'getter', 'setter'],
    ['integralLimitInterval', 216, 'X216', 'getter', 'setter'],
    ['amount0', 256, 'X127', 'getter', 'setter'],
    ['amount1', 256, 'X127', 'getter', 'setter'],
    ['back', 496],
    ['next', 496],
    ['backGrowthMultiplier', 256, 'X208', 'getter', 'setter'],
    ['nextGrowthMultiplier', 256, 'X208', 'getter', 'setter'],
    ['interval', 0],
    ['direction', 8, 'bool', 'getter', 'setter'],
    ['indexCurve', 16, 'Index', 'getter', 'setter'],
    ['indexKernelTotal', 16],
    ['indexKernelForward', 16],
    ['logPriceLimitOffsettedWithinInterval', 64, 'X59', 'getter', 'setter'],
    ['current', 496],
    ['origin', 496],
    ['begin', 496],
    ['end', 496],
    ['target', 496],
    ['overshoot', 496],
    ['total0', 512],
    ['total1', 512],
    ['forward0', 512],
    ['forward1', 512],
    ['incomingCurrentToTarget', 216],
    ['currentToTarget', 216],
    ['currentToOrigin', 216],
    ['currentToOvershoot', 216],
    ['targetToOvershoot', 216],
    ['originToOvershoot', 216],
    ['endOfInterval', 0],
    ['accruedParams', 0],
    ['accrued0', 256, 'X127', 'getter', 'setter'],
    ['accrued1', 256, 'X127', 'getter', 'setter'],
    ['poolRatio0', 24, 'X23', 'getter', 'setter'],
    ['poolRatio1', 24, 'X23', 'getter', 'setter'],
    ['pointers', 0],
    ['kernel', 256, 'Kernel', 'getter', 'setter'],
    ['curve', 256, 'Curve', 'getter', 'setter'],
    ['hookData', 256, 'uint256', 'getter', 'setter'],
    ['kernelLength', 16, 'Index', 'getter', 'setter'],
    ['curveLength', 16, 'Index', 'getter', 'setter'],
    ['hookDataByteCount', 16, 'uint16', 'getter', 'setter'],
    ['dynamicParams', 0],
    ['staticParamsStoragePointerExtension', 256, 'uint256', 'getter', 'setter'],
    ['staticParamsStoragePointer', 16, 'uint16', 'getter', 'setter'],
    ['logPriceCurrent', 64, 'X59', 'getter', 'setter'],
    ['sharesTotal', 128, 'uint256', 'getter', 'setter'],
    ['growth', 128, 'X111', 'getter', 'setter'],
    ['integral0', 216, 'X216', 'getter', 'setter'],
    ['integral1', 216, 'X216', 'getter', 'setter'],
    ['deploymentCreationCode', 88, 'uint256', 'setter'],
    ['staticParams', 0],
    ['tag0', 256, 'Tag', 'getter', 'setter'],
    ['tag1', 256, 'Tag', 'getter', 'setter'],
    ['sqrtOffset', 256, 'X127', 'getter', 'setter'],
    ['sqrtInverseOffset', 256, 'X127', 'getter', 'setter'],
    ['spacing', 496],
    ['outgoingMax', 216, 'X216', 'getter', 'setter'],
    ['outgoingMaxModularInverse', 256, 'uint256', 'getter', 'setter'],
    ['incomingMax', 216, 'X216', 'getter', 'setter'],
    ['poolGrowthPortion', 48, 'X47', 'getter', 'setter'],
    ['maxPoolGrowthPortion', 48, 'X47', 'getter', 'setter'],
    ['protocolGrowthPortion', 48, 'X47', 'getter', 'setter'],
    ['pendingKernelLength', 16, 'Index', 'getter', 'setter'],
    ['endOfStaticParams', 0],
]

# Given a memory layout, the following script generates all the pointers and
# getter/setter functions.
s = 512
for k in variables:
    if k[0] == 'hookSelector':
        print()
    if k[0] == 'swapInput':
        print()
    if k[0] == 'swapParams':
        print()
    if k[0] == 'interval':
        print()
    if k[0] == 'dynamicParams':
        print()
    if k[0] == 'accruedParams':
        print()
    if k[0] == 'pointers':
        print()
    if k[0] == 'deploymentCreationCode':
        print()
    if k[0] == 'staticParams':
        print()
    if k[0] == 'endOfStaticParams':
        print()
    if k[1] != 512:
        print('uint16 constant _' + k[0] + '_ = ' + str(s // 8) + ';')
    else:
        print('uint16 constant _' + k[0] + '_ = ' + str(2 + s // 8) + ';')
    s = s + k[1]

for k in variables:
    if 'getter' in k:
        print()
        print('function get' + k[0][0].upper() + k[0][1:] + '() pure returns (')
        print('  ' + k[2] + ' ' + k[0])
        print(') {')
        print('  assembly {')
        if k[2] == 'bool':
            print('    ' + k[0] + ' := shr(255, mload(_' + k[0] + '_))')
        elif k[1] == 256:
            print('    ' + k[0] + ' := mload(_' + k[0] + '_)')
        else:
            print('    ' + k[0] + ' := shr(' + str(256 - k[1]) + ', mload(_' + k[0] + '_))')
        print('  }')
        print('}')
        
    if 'setter' in k:
        print()
        print('function set' + k[0][0].upper() + k[0][1:] + '(')
        print('  ' + k[2] + ' ' + k[0])
        print(') pure {')
        print('  assembly {')
        if k[2] == 'bool':
            print('    mstore8(_' + k[0] + '_, mul(0xFF, ' + k[0] + '))')
        elif k[1] == 256:
            print('    mstore(_' + k[0] + '_, ' + k[0] + ')')
        else:
            print('    mstore(')
            print('      _' + k[0] + '_,')
            print('      or(')
            print('        shl(' + str(256 - k[1]) + ', ' + k[0] + '),')
            print('        shr(' + str(k[1]) + ', mload(add(_' + k[0] + '_, ' + str(k[1] // 8) + ')))')
            print('      )')
            print('    )')
        print('  }')
        print('}')

# ModifyPositionOperator memory layout
variables = [
    ['freeMemoryPointer', 256, 'uint16', 'getter', 'setter'],
    ['blank', 256],
    ['hookSelector', 32, 'uint256', 'setter'],
    ['hookDataHeader', 256, 'uint256', 'setter'],
    ['hookDataByteCount', 256, 'uint256', 'getter', 'setter'],
    ['msgSender', 160, 'address', 'setter'],
    ['poolId', 256, 'uint256'],
    ['modifyPositionInput', 0],
    ['logPriceMinOffsetted', 64, 'X59', 'getter', 'setter'],
    ['logPriceMaxOffsetted', 64, 'X59', 'getter', 'setter'],
    ['shares', 256, 'int256', 'getter', 'setter'],
    ['logPriceMin', 256, 'X59', 'getter', 'setter'],
    ['logPriceMax', 256, 'X59', 'getter', 'setter'],
    ['positionAmount0', 256, 'int256', 'getter', 'setter'],
    ['positionAmount1', 256, 'int256', 'getter', 'setter'],
    ['endOfModifyPosition', 0],
]

# Given a memory layout, the following script generates all the getter/setter 
# functions for a hook contract to access the given variables from calldata.
s = 0
for k in variables[2:]:
    if k[0] == 'hookSelector':
        print()
    if k[0] == 'swapInput':
        print()
    if k[0] == 'swapParams':
        print()
    if k[0] == 'interval':
        print()
    if k[0] == 'dynamicParams':
        print()
    if k[0] == 'accruedParams':
        print()
    if k[0] == 'pointers':
        print()
    if k[0] == 'deploymentCreationCode':
        print()
    if k[0] == 'staticParams':
        print()
    if k[0] == 'endOfStaticParams':
        print()
    if k[1] != 512:
        print('uint16 constant _' + k[0] + 'Calldata_ = ' + str(s // 8) + ';')
    else:
        print('uint16 constant _' + k[0] + 'Calldata_ = ' + str(2 + s // 8) + ';')
    s = s + k[1]

for k in variables[2:]:
    if 'getter' in k or 'setter' in k:
        print()
        print('function get' + k[0][0].upper() + k[0][1:] + 'FromCalldata() pure returns (')
        print('  ' + k[2] + ' ' + k[0] + 'Calldata')
        print(') {')
        print('  assembly {')
        if k[2] == 'bool':
            print('    ' + k[0] + 'Calldata := shr(255, calldataload(_' + k[0] + 'Calldata_))')
        elif k[1] == 256:
            print('    ' + k[0] + 'Calldata := calldataload(_' + k[0] + 'Calldata_)')
        elif k[0] == 'curve':
            print('    ' + k[0] + 'Calldata := sub(shr(' + str(256 - k[1]) + ', calldataload(_' + k[0] + 'Calldata_)), _hookSelector_)')
        elif k[0] == 'kernel':
            print('    ' + k[0] + 'Calldata := sub(shr(' + str(256 - k[1]) + ', calldataload(_' + k[0] + 'Calldata_)), _hookSelector_)')
        elif k[0] == 'hookData':
            print('    ' + k[0] + 'Calldata := sub(shr(' + str(256 - k[1]) + ', calldataload(_' + k[0] + 'Calldata_)), _hookSelector_)')
        else:
            print('    ' + k[0] + 'Calldata := shr(' + str(256 - k[1]) + ', calldataload(_' + k[0] + 'Calldata_))')
        print('  }')
        print('}')

s = 512
for k in variables:
    if k[0] == 'hookSelector':
        print()
    if k[0] == 'swapInput':
        print()
    if k[0] == 'swapParams':
        print()
    if k[0] == 'interval':
        print()
    if k[0] == 'dynamicParams':
        print()
    if k[0] == 'accruedParams':
        print()
    if k[0] == 'pointers':
        print()
    if k[0] == 'deploymentCreationCode':
        print()
    if k[0] == 'staticParams':
        print()
    if k[0] == 'endOfStaticParams':
        print()
    if k[1] != 0:
        print(str(s // 8) + (5 - len(str(s // 8))) * ' ' + 'X' * (k[1] // 8) + (72 - (k[1] // 8)) * ' ' + k[0] + (50 - len(k[0])) * ' ' + str(k[1]))
    else:
        print(str(s // 8) + (5 - len(str(s // 8))) * ' ' + k[0])
    s = s + k[1]

# 0    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX                                        scratchSpace0                                     256
# 32   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX                                        scratchSpace1                                     256
# 64   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX                                        freeMemoryPointer                                 256
# 96   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX                                        blank                                             256

# 128  XXXX                                                                    hookSelector                                      32
# 132  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX                                        hookInputHeader                                   256
# 164  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX                                        hookInputByteCount                                256
# 196  XXXXXXXXXXXXXXXXXXXX                                                    msgSender                                         160
# 216  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX                                        poolId                                            256

# 248  swapInput
# 248  XXXXXXXXXXXXXXXX                                                        crossThreshold                                    128
# 264  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX                                        amountSpecified                                   256
# 296  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX                                        logPriceLimit                                     256
# 328  XXXXXXXX                                                                logPriceLimitOffsetted                            64

# 336  swapParams
# 336  X                                                                       zeroForOne                                        8
# 337  X                                                                       exactInput                                        8
# 338  XXXXXXXXXXXXXXXXXXXXXXXXXXX                                             integralLimit                                     216
# 365  XXXXXXXXXXXXXXXXXXXXXXXXXXX                                             integralLimitInterval                             216
# 392  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX                                        amount0                                           256
# 424  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX                                        amount1                                           256
# 456  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX          back                                              496
# 518  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX          next                                              496
# 580  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX                                        backGrowthMultiplier                              256
# 612  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX                                        nextGrowthMultiplier                              256

# 644  interval
# 644  X                                                                       direction                                         8
# 645  XX                                                                      indexCurve                                        16
# 647  XX                                                                      indexKernelTotal                                  16
# 649  XX                                                                      indexKernelForward                                16
# 651  XXXXXXXX                                                                logPriceLimitOffsettedWithinInterval              64
# 659  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX          current                                           496
# 721  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX          origin                                            496
# 783  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX          begin                                             496
# 845  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX          end                                               496
# 907  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX          target                                            496
# 969  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX          overshoot                                         496
# 1031 XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX        total0                                            512
# 1095 XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX        total1                                            512
# 1159 XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX        forward0                                          512
# 1223 XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX        forward1                                          512
# 1287 XXXXXXXXXXXXXXXXXXXXXXXXXXX                                             incomingCurrentToTarget                           216
# 1314 XXXXXXXXXXXXXXXXXXXXXXXXXXX                                             currentToTarget                                   216
# 1341 XXXXXXXXXXXXXXXXXXXXXXXXXXX                                             currentToOrigin                                   216
# 1368 XXXXXXXXXXXXXXXXXXXXXXXXXXX                                             currentToOvershoot                                216
# 1395 XXXXXXXXXXXXXXXXXXXXXXXXXXX                                             targetToOvershoot                                 216
# 1422 XXXXXXXXXXXXXXXXXXXXXXXXXXX                                             originToOvershoot                                 216

# 1449 accruedParams

# 1449 accruedParams
# 1449 XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX                                        accrued0                                          256
# 1481 XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX                                        accrued1                                          256
# 1513 XXX                                                                     poolRatio0                                        24
# 1516 XXX                                                                     poolRatio1                                        24

# 1519 pointers
# 1519 XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX                                        kernel                                            256
# 1551 XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX                                        curve                                             256
# 1583 XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX                                        hookData                                          256
# 1615 XX                                                                      kernelLength                                      16
# 1617 XX                                                                      curveLength                                       16
# 1619 XX                                                                      hookDataByteCount                                 16

# 1621 dynamicParams
# 1621 XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX                                        staticParamsStoragePointerExtension               256
# 1653 XX                                                                      staticParamsStoragePointer                        16
# 1655 XXXXXXXX                                                                logPriceCurrent                                   64
# 1663 XXXXXXXXXXXXXXXX                                                        sharesTotal                                       128
# 1679 XXXXXXXXXXXXXXXX                                                        growth                                            128
# 1695 XXXXXXXXXXXXXXXXXXXXXXXXXXX                                             integral0                                         216
# 1722 XXXXXXXXXXXXXXXXXXXXXXXXXXX                                             integral1                                         216

# 1749 XXXXXXXXXXX                                                             deploymentCreationCode                            88

# 1760 staticParams
# 1760 XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX                                        tag0                                              256
# 1792 XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX                                        tag1                                              256
# 1824 XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX                                        sqrtOffset                                        256
# 1856 XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX                                        sqrtInverseOffset                                 256
# 1888 XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX          spacing                                           496
# 1950 XXXXXXXXXXXXXXXXXXXXXXXXXXX                                             outgoingMax                                       216
# 1977 XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX                                        outgoingMaxModularInverse                         256
# 2009 XXXXXXXXXXXXXXXXXXXXXXXXXXX                                             incomingMax                                       216
# 2036 XXXXXX                                                                  poolGrowthPortion                                 48
# 2042 XXXXXX                                                                  maxPoolGrowthPortion                              48
# 2048 XXXXXX                                                                  protocolGrowthPortion                             48
# 2054 XX                                                                      pendingKernelLength                               16

# 2056 endOfStaticParams