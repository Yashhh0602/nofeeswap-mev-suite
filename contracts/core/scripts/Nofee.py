# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import os
import time
from sympy import Integer, Symbol, Piecewise, And, floor, piecewise_fold, exp, N
from sha3 import keccak_256
from eth_abi import encode
from eth_abi.packed import encode_packed

minLogStep = (1 << 59) >> 27
minLogSpacing = (1 << 59) >> 19
thirtyTwoX59 = 1 << 64

isPreInitialize = 1 << 160
isPostInitialize = 1 << 161
isPreMint = 1 << 162
isMidMint = 1 << 163
isPostMint = 1 << 164
isPreBurn = 1 << 165
isMidBurn = 1 << 166
isPostBurn = 1 << 167
isPreSwap = 1 << 168
isMidSwap = 1 << 169
isPostSwap = 1 << 170
isPreDonate = 1 << 171
isMidDonate = 1 << 172
isPostDonate = 1 << 173
isPreModifyKernel = 1 << 174
isMidModifyKernel = 1 << 175
isPostModifyKernel = 1 << 176
isMutableKernel = 1 << 177
isMutablePoolGrowthPortion = 1 << 178
isDonateAllowed = 1 << 179

_freeMemoryPointer_ = 64
_blank_ = 96
_hookSelector_ = 128
_hookInputHeader_ = 132
_hookInputByteCount_ = 164
_msgSender_ = 196
_poolId_ = 216
_swapInput_ = 248
_crossThreshold_ = 248
_amountSpecified_ = 264
_logPriceLimit_ = 296
_logPriceLimitOffsetted_ = 328
_swapParams_ = 336
_zeroForOne_ = 336
_exactInput_ = 337
_integralLimit_ = 338
_integralLimitInterval_ = 365
_amount0_ = 392
_amount1_ = 424
_back_ = 456
_next_ = 518
_backGrowthMultiplier_ = 580
_nextGrowthMultiplier_ = 612
_interval_ = 644
_direction_ = 644
_indexCurve_ = 645
_indexKernelTotal_ = 647
_indexKernelForward_ = 649
_logPriceLimitOffsettedWithinInterval_ = 651
_current_ = 659
_origin_ = 721
_begin_ = 783
_end_ = 845
_target_ = 907
_overshoot_ = 969
_total0_ = 1033
_total1_ = 1097
_forward0_ = 1161
_forward1_ = 1225
_incomingCurrentToTarget_ = 1287
_currentToTarget_ = 1314
_currentToOrigin_ = 1341
_currentToOvershoot_ = 1368
_targetToOvershoot_ = 1395
_originToOvershoot_ = 1422
_accruedParams_ = 1449
_accrued0_ = 1449
_accrued1_ = 1481
_poolRatio0_ = 1513
_poolRatio1_ = 1516
_pointers_ = 1519
_kernel_ = 1519
_curve_ = 1551
_hookData_ = 1583
_kernelLength_ = 1615
_curveLength_ = 1617
_hookDataByteCount_ = 1619
_dynamicParams_ = 1621
_staticParamsStoragePointer_ = 1653
_logPriceCurrent_ = 1655
_sharesTotal_ = 1663
_growth_ = 1679
_integral0_ = 1695
_integral1_ = 1722
_deploymentCreationCode_ = 1749
_staticParams_ = 1760
_tag0_ = 1760
_tag1_ = 1792
_sqrtOffset_ = 1824
_sqrtInverseOffset_ = 1856
_spacing_ = 1888
_outgoingMax_ = 1950
_outgoingMaxModularInverse_ = 1977
_incomingMax_ = 2009
_poolGrowthPortion_ = 2036
_maxPoolGrowthPortion_ = 2042
_protocolGrowthPortion_ = 2048
_pendingKernelLength_ = 2054
_endOfStaticParams_ = 2056
_modifyPositionInput_ = 248
_logPriceMinOffsetted_ = 248
_logPriceMaxOffsetted_ = 256
_shares_ = 264
_logPriceMin_ = 296
_logPriceMax_ = 328
_positionAmount0_ = 360
_positionAmount1_ = 392
_endOfModifyPosition_ = 424

X15 = 2**15
X59 = 2**59
X63 = 2**63
X60 = 2**60
X64 = 2**64
X216 = 2**216
X256 = 2**256

address0 = '0x0000000000000000000000000000000000000000'

def logTest(request, worker_id):
    if os.path.exists('testLogs') == False:
        os.mkdir('testLogs')
    path = os.path.relpath('./testLogs/'+ worker_id + ".md", os.getcwd())

    num = 1
    if hasattr(request.function, 'pytestmark'):
        for kk in range(len(request.function.pytestmark)):
            num *= len(request.function.pytestmark[kk].args[1])

    if os.path.isfile(path):
        with open(path, "r+") as f:
            old = f.read()
            start = old.find('\n')
            index = int(old[0:start])
            old = old[start+1:]
            start = old.find('\n')
            pastTime = float(old[0:start])
            index += 1
        content = str(index) + '\n' + str(time.time()) + old[start:]
    else:
        with open(path, "a") as f:
            f.seek(0)
        index = 1
        content = str(index) + "\n" + str(time.time()) + "\n\n"
        pastTime = time.time()

    content += request.fspath.basename + '\n' + str(request.function)
    for fixture in [item for item in request.fixturenames if item not in ["request"]]:
        content += '\n'
        content += fixture + ' == ' + str(request.getfixturevalue(fixture))
    content += '\n' + 'total == ' + str(num)
    content += '\n' + 'time == ' + str(time.time() - pastTime) + '\n\n'

    with open(path, "r+") as f:
        f.seek(0)
        f.write(content)

def keccak(types, values):
    return toInt(keccak_256(encode(types, values)).hexdigest())

def keccakPacked(types, values):
    return toInt(keccak_256(encode_packed(types, values)).hexdigest())

def keccak256(input):
    return toInt(keccak_256(input.encode('utf-8')).digest().hex())

def getPoolId(sender, unsaltedPoolId):
    return (unsaltedPoolId + (toInt(keccak_256(((toInt(sender) << 256) + unsaltedPoolId).to_bytes(52, 'big')).hexdigest()) << 188)) % (1 << 256)

def addOffset(input):
    if type(input) is list:
        return [value + X63 for value in input]
    else:
        return input + X63

def subOffset(input):
    if type(input) is list:
        return [value - X63 for value in input]
    else:
        return input - X63
    
def toRational(input):
    if type(input) is list:
        return [(value - X63) / Integer(X59) for value in input]
    else:
        return (input - X63) / Integer(X59)

def getBoundaries(curve):
    return min(curve[0], curve[1]), max(curve[0], curve[1])

def dataGeneration(n):
    logPriceTickX59 = 57643193118714

    feeSpacingSmallX59 = 288302457773874 # 0.05% fee
    feeSpacingMediumX59 = 1731981530143823 # 0.3% fee
    feeSpacingLargeX59 = 5793624167011548 # 1.0% fee

    logPriceSpacingSmallX59 = 10 * logPriceTickX59
    logPriceSpacingMediumX59 = 60 * logPriceTickX59
    logPriceSpacingLargeX59 = 200 * logPriceTickX59

    horizontalSteps = [0, 2**32, X64 - 2**32 - 1]
    verticalSteps = [0, 1, X15 // 2, X15 - 1, X15]
    prices = addOffset([
        0,
        -1, +1,
        # -feeSpacingSmallX59, +feeSpacingSmallX59,
        -logPriceSpacingSmallX59, +logPriceSpacingSmallX59,
        -logPriceSpacingLargeX59, +logPriceSpacingLargeX59
        # -feeSpacingSmallX59,
        # +logPriceSpacingLargeX59
    ])

    # A list of valid kernels of various sizes and shapes to be used for testing
    kernelsValid = [
        [
            [0, 0], 
            [1*logPriceSpacingSmallX59, 1*X15 // 8], 
            [1*logPriceSpacingSmallX59, 2*X15 // 8], 
            [2*logPriceSpacingSmallX59, 2*X15 // 8], 
            [3*logPriceSpacingSmallX59, 8*X15 // 8]
        ],
        [
            [0, 0], 
            [1*logPriceSpacingSmallX59, 1*X15 // 8], 
            [1*logPriceSpacingSmallX59, 2*X15 // 8], 
            [2*logPriceSpacingSmallX59, 2*X15 // 8], 
            [3*logPriceSpacingSmallX59, 3*X15 // 8], 
            [4*logPriceSpacingSmallX59, 8*X15 // 8]
        ],
        [
            [0, 0], 
            [1*logPriceSpacingSmallX59, 1*X15 // 8], 
            [1*logPriceSpacingSmallX59, 2*X15 // 8], 
            [2*logPriceSpacingSmallX59, 2*X15 // 8], 
            [3*logPriceSpacingSmallX59, 3*X15 // 8], 
            [3*logPriceSpacingSmallX59, 4*X15 // 8], 
            [4*logPriceSpacingSmallX59, 8*X15 // 8]
        ],
        [
            [0, 0], 
            [1*logPriceSpacingSmallX59, 1*X15 // 8], 
            [1*logPriceSpacingSmallX59, 2*X15 // 8], 
            [2*logPriceSpacingSmallX59, 2*X15 // 8], 
            [3*logPriceSpacingSmallX59, 3*X15 // 8], 
            [3*logPriceSpacingSmallX59, 4*X15 // 8], 
            [4*logPriceSpacingSmallX59, 4*X15 // 8], 
            [5*logPriceSpacingSmallX59, 8*X15 // 8]
        ],
        [
            [0, 0], 
            [1*logPriceSpacingSmallX59, 1*X15 // 8], 
            [1*logPriceSpacingSmallX59, 2*X15 // 8], 
            [2*logPriceSpacingSmallX59, 2*X15 // 8], 
            [3*logPriceSpacingSmallX59, 3*X15 // 8], 
            [3*logPriceSpacingSmallX59, 4*X15 // 8], 
            [4*logPriceSpacingSmallX59, 4*X15 // 8], 
            [5*logPriceSpacingSmallX59, 5*X15 // 8], 
            [6*logPriceSpacingSmallX59, 8*X15 // 8]
        ],
        [
            [0, 0], 
            [1*logPriceSpacingSmallX59, 0*X15 // 8], 
            [2*logPriceSpacingSmallX59, 1*X15 // 8], 
            [2*logPriceSpacingSmallX59, 2*X15 // 8], 
            [3*logPriceSpacingSmallX59, 8*X15 // 8]
        ],
        [
            [0, 0], 
            [1*logPriceSpacingSmallX59, 0*X15 // 8], 
            [2*logPriceSpacingSmallX59, 1*X15 // 8], 
            [2*logPriceSpacingSmallX59, 2*X15 // 8], 
            [3*logPriceSpacingSmallX59, 2*X15 // 8], 
            [4*logPriceSpacingSmallX59, 8*X15 // 8]
        ],
        [
            [0, 0], 
            [1*logPriceSpacingSmallX59, 0*X15 // 8], 
            [2*logPriceSpacingSmallX59, 1*X15 // 8], 
            [2*logPriceSpacingSmallX59, 2*X15 // 8], 
            [3*logPriceSpacingSmallX59, 2*X15 // 8], 
            [4*logPriceSpacingSmallX59, 3*X15 // 8], 
            [5*logPriceSpacingSmallX59, 8*X15 // 8]
        ],
        [
            [0, 0], 
            [1*logPriceSpacingSmallX59, 0*X15 // 8], 
            [2*logPriceSpacingSmallX59, 1*X15 // 8], 
            [2*logPriceSpacingSmallX59, 2*X15 // 8], 
            [3*logPriceSpacingSmallX59, 2*X15 // 8], 
            [4*logPriceSpacingSmallX59, 3*X15 // 8], 
            [4*logPriceSpacingSmallX59, 8*X15 // 8], 
            [5*logPriceSpacingSmallX59, 8*X15 // 8]
        ],
        [
            [0, 0], 
            [1*logPriceSpacingSmallX59, 0*X15 // 8], 
            [2*logPriceSpacingSmallX59, 1*X15 // 8], 
            [2*logPriceSpacingSmallX59, 2*X15 // 8], 
            [3*logPriceSpacingSmallX59, 2*X15 // 8], 
            [4*logPriceSpacingSmallX59, 3*X15 // 8], 
            [4*logPriceSpacingSmallX59, 4*X15 // 8], 
            [5*logPriceSpacingSmallX59, 4*X15 // 8], 
            [6*logPriceSpacingSmallX59, 8*X15 // 8]
        ],
        [
            [0, 0], 
            [1*logPriceSpacingSmallX59, 0*X15 // 8], 
            [2*logPriceSpacingSmallX59, 1*X15 // 8], 
            [2*logPriceSpacingSmallX59, 2*X15 // 8], 
            [3*logPriceSpacingSmallX59, 2*X15 // 8], 
            [4*logPriceSpacingSmallX59, 3*X15 // 8], 
            [4*logPriceSpacingSmallX59, 4*X15 // 8], 
            [5*logPriceSpacingSmallX59, 4*X15 // 8], 
            [6*logPriceSpacingSmallX59, 8*X15 // 8]
        ],
        [
            [0, 0], 
            [1*logPriceSpacingSmallX59, 0*X15 // 8], 
            [2*logPriceSpacingSmallX59, 1*X15 // 8], 
            [3*logPriceSpacingSmallX59, 1*X15 // 8], 
            [4*logPriceSpacingSmallX59, 2*X15 // 8], 
            [5*logPriceSpacingSmallX59, 2*X15 // 8], 
            [6*logPriceSpacingSmallX59, 3*X15 // 8], 
            [7*logPriceSpacingSmallX59, 3*X15 // 8], 
            [8*logPriceSpacingSmallX59, 8*X15 // 8]
        ],
        [
            [0, 0], 
            [1*logPriceSpacingSmallX59, 0*X15 // 8], 
            [1*logPriceSpacingSmallX59, 1*X15 // 8], 
            [2*logPriceSpacingSmallX59, 1*X15 // 8], 
            [2*logPriceSpacingSmallX59, 2*X15 // 8], 
            [3*logPriceSpacingSmallX59, 2*X15 // 8], 
            [3*logPriceSpacingSmallX59, 3*X15 // 8], 
            [4*logPriceSpacingSmallX59, 3*X15 // 8], 
            [5*logPriceSpacingSmallX59, 8*X15 // 8]
        ],
        [
            [0, 0], 
            [1*logPriceSpacingSmallX59, 0*X15 // 8], 
            [1*logPriceSpacingSmallX59, 1*X15 // 8], 
            [2*logPriceSpacingSmallX59, 2*X15 // 8], 
            [3*logPriceSpacingSmallX59, 2*X15 // 8], 
            [3*logPriceSpacingSmallX59, 3*X15 // 8], 
            [4*logPriceSpacingSmallX59, 4*X15 // 8], 
            [5*logPriceSpacingSmallX59, 4*X15 // 8], 
            [6*logPriceSpacingSmallX59, 8*X15 // 8]
        ],
        [
            [0, 0], 
            [1*logPriceSpacingSmallX59, 1*X15 // 8], 
            [2*logPriceSpacingSmallX59, 1*X15 // 8], 
            [2*logPriceSpacingSmallX59, 2*X15 // 8], 
            [3*logPriceSpacingSmallX59, 3*X15 // 8], 
            [4*logPriceSpacingSmallX59, 3*X15 // 8], 
            [4*logPriceSpacingSmallX59, 4*X15 // 8], 
            [5*logPriceSpacingSmallX59, 5*X15 // 8], 
            [6*logPriceSpacingSmallX59, 8*X15 // 8]
        ],
        [
            [0, 0], 
            [1*logPriceSpacingSmallX59, 1*X15 // 8], 
            [1*logPriceSpacingSmallX59, 2*X15 // 8], 
            [2*logPriceSpacingSmallX59, 2*X15 // 8], 
            [3*logPriceSpacingSmallX59, 3*X15 // 8], 
            [3*logPriceSpacingSmallX59, 4*X15 // 8], 
            [4*logPriceSpacingSmallX59, 4*X15 // 8], 
            [5*logPriceSpacingSmallX59, 5*X15 // 8], 
            [6*logPriceSpacingSmallX59, 8*X15 // 8]
        ],
        [
            [0, 0], 
            [1*logPriceSpacingSmallX59, 1*X15 // 8], 
            [1*logPriceSpacingSmallX59, 2*X15 // 8], 
            [2*logPriceSpacingSmallX59, 3*X15 // 8], 
            [2*logPriceSpacingSmallX59, 4*X15 // 8], 
            [3*logPriceSpacingSmallX59, 5*X15 // 8], 
            [3*logPriceSpacingSmallX59, 6*X15 // 8], 
            [4*logPriceSpacingSmallX59, 6*X15 // 8], 
            [5*logPriceSpacingSmallX59, 8*X15 // 8]
        ],
        [
            [0, 0], 
            [1*logPriceSpacingSmallX59, 1*X15 // 8], 
            [2*logPriceSpacingSmallX59, 1*X15 // 8], 
            [3*logPriceSpacingSmallX59, 2*X15 // 8], 
            [4*logPriceSpacingSmallX59, 2*X15 // 8], 
            [5*logPriceSpacingSmallX59, 3*X15 // 8], 
            [6*logPriceSpacingSmallX59, 3*X15 // 8], 
            [7*logPriceSpacingSmallX59, 4*X15 // 8], 
            [9*logPriceSpacingSmallX59, 8*X15 // 8]
        ]
    ]

    for horizontalStep1X59 in horizontalSteps:
        for verticalStep1X15 in verticalSteps:
            valid1 = (horizontalStep1X59 != 0)
            if valid1 and horizontalStep1X59 >= 2 ** 40:
                kernel1 = [[0, 0], [horizontalStep1X59, verticalStep1X15]]
                if verticalStep1X15 == X15:
                    if kernel1 not in kernelsValid:
                        kernelsValid += [kernel1]
                for horizontalStep2X59 in horizontalSteps:
                    for verticalStep2X15 in verticalSteps:
                        valid2 = ((horizontalStep2X59 != 0) or (verticalStep2X15 != 0)) and \
                            (verticalStep1X15 + verticalStep2X15 <= X15) and \
                            ((verticalStep1X15 != 0) or (verticalStep2X15 != 0)) and \
                            ((horizontalStep1X59 != 0) or (horizontalStep2X59 != 0)) and \
                            (2 ** 40 <= horizontalStep1X59 + horizontalStep2X59 < X64 - 1)
                        if valid2:
                            kernel2 = [
                                [0, 0], 
                                [horizontalStep1X59, verticalStep1X15], 
                                [horizontalStep1X59 + horizontalStep2X59, verticalStep1X15 + verticalStep2X15]
                            ]
                            if (verticalStep1X15 + verticalStep2X15 == X15) and (horizontalStep2X59 != 0):
                                if kernel2 not in kernelsValid:
                                    kernelsValid += [kernel2]
                            for horizontalStep3X59 in horizontalSteps:
                                for verticalStep3X15 in verticalSteps:
                                    valid3 = ((horizontalStep3X59 != 0) or (verticalStep3X15 != 0)) and \
                                        ((verticalStep2X15 != 0) or (verticalStep3X15 != 0)) and \
                                        ((horizontalStep2X59 != 0) or (horizontalStep3X59 != 0)) and \
                                        (2 ** 40 <= horizontalStep1X59 + horizontalStep2X59 + horizontalStep3X59 < X64 - 1)
                                    if valid3:
                                        kernel3 = [
                                            [0, 0], 
                                            [horizontalStep1X59, verticalStep1X15], 
                                            [horizontalStep1X59 + horizontalStep2X59, verticalStep1X15 + verticalStep2X15], 
                                            [horizontalStep1X59 + horizontalStep2X59 + horizontalStep3X59, verticalStep1X15 + verticalStep2X15 + verticalStep3X15]
                                        ]
                                        if (verticalStep1X15 + verticalStep2X15 + verticalStep3X15 == X15) and (horizontalStep3X59 != 0) and (horizontalStep1X59 + horizontalStep2X59 + horizontalStep3X59 >= 2 ** 40):
                                            if kernel3 not in kernelsValid:
                                                kernelsValid += [kernel3]

    # A list of kernels that are not valid
    kernelsInvalid = [[[0, 0]]]
    for horizontalStep1X59 in horizontalSteps:
        for verticalStep1X15 in verticalSteps:
            kernel1 = [[0, 0], [horizontalStep1X59, verticalStep1X15]]
            kernelsInvalid += [kernel1]
            for horizontalStep2X59 in horizontalSteps:
                for verticalStep2X15 in verticalSteps:
                    kernel2 = [
                        [0, 0], 
                        [horizontalStep1X59, verticalStep1X15], 
                        [horizontalStep1X59 + horizontalStep2X59, verticalStep1X15 + verticalStep2X15]
                    ]
                    kernelsInvalid += [kernel2]
                    for horizontalStep3X59 in horizontalSteps:
                        for verticalStep3X15 in verticalSteps:
                            kernel3 = [
                                [0, 0], 
                                [horizontalStep1X59, verticalStep1X15], 
                                [horizontalStep1X59 + horizontalStep2X59, verticalStep1X15 + verticalStep2X15], 
                                [horizontalStep1X59 + horizontalStep2X59 + horizontalStep3X59, verticalStep1X15 + verticalStep2X15 + verticalStep3X15]
                            ]
                            kernelsInvalid += [kernel3]
    kernelsInvalid = [kernel for kernel in kernelsInvalid if (
        (kernel not in kernelsValid) and (kernel[-1][1] <= X15) and (kernel[-1][1] != kernel[-2][1] if len(kernel) > 1 else True)
    )]

    # A list of curves
    curves = [[] for t in kernelsValid]
    for i in range(len(kernelsValid)):
        for price0X59 in prices:
            for price1X59 in [price0X59 + kernelsValid[i][-1][0], price0X59 - kernelsValid[i][-1][0]]:
                if price1X59 > 0 and price1X59 < X64:
                    curve1 = [price0X59, price1X59]
                    curves[i] += [curve1]
                    for price2X59 in prices:
                        if min(price0X59, price1X59) < price2X59 < max(price0X59, price1X59):
                            curve2 = [price0X59, price1X59, price2X59]
                            curves[i] += [curve2]
                            for price3X59 in prices:
                                if min(price1X59, price2X59) < price3X59 < max(price1X59, price2X59):
                                    curve3 = [price0X59, price1X59, price2X59, price3X59]
                                    curves[i] += [curve3]
                                    for price4X59 in prices:
                                        if min(price2X59, price3X59) < price4X59 < max(price2X59, price3X59):
                                            curve4 = [price0X59, price1X59, price2X59, price3X59, price4X59]
                                            curves[i] += [curve4]
                                            for price5X59 in prices:
                                                if min(price3X59, price4X59) < price5X59 < max(price3X59, price4X59):
                                                    curve5 = [price0X59, price1X59, price2X59, price3X59, price4X59, price5X59]
                                                    curves[i] += [curve5]
                                                    for price6X59 in prices:
                                                        if min(price4X59, price5X59) < price6X59 < max(price4X59, price5X59):
                                                            curve6 = [price0X59, price1X59, price2X59, price3X59, price4X59, price5X59, price6X59]
                                                            curves[i] += [curve6]
                                                            for price7X59 in prices:
                                                                if min(price5X59, price6X59) < price7X59 < max(price5X59, price6X59):
                                                                    curve7 = [price0X59, price1X59, price2X59, price3X59, price4X59, price5X59, price6X59, price7X59]
                                                                    curves[i] += [curve7]
                                                                    for price8X59 in prices:
                                                                        if min(price6X59, price7X59) < price8X59 < max(price6X59, price7X59):
                                                                            curve8 = [price0X59, price1X59, price2X59, price3X59, price4X59, price5X59, price6X59, price7X59, price8X59]
                                                                            curves[i] += [curve8]

    initializations = dict()
    initializations['kernel'] = []
    initializations['curve'] = []
    for k in range(min(n, len(kernelsValid))):
        # if k % 20 == 0:
        #     print('Data generation', k, 'out of', min(n, len(kernelsValid)))
        kernel = kernelsValid[k]
        for curve in curves[k]:
            initializations['kernel'] = initializations['kernel'] + [kernel]
            initializations['curve'] = initializations['curve'] + [curve]

    swaps = dict()
    swaps['kernel'] = []
    swaps['curve'] = []
    swaps['target'] = []
    for k in range(min(n, len(kernelsValid))):
        # if k % 20 == 0:
        #     print('Data generation', k, 'out of', min(n, len(kernelsValid)))
        kernel = kernelsValid[k]
        for curve in curves[k]:
            for targetX59 in prices:
                qLowerX59, qUpperX59 = getBoundaries(curve)
                if (targetX59 != curve[-1]) and (qLowerX59 < targetX59) and (targetX59 < qUpperX59):
                    swaps['kernel'] = swaps['kernel'] + [kernel]
                    swaps['curve'] = swaps['curve'] + [curve]
                    swaps['target'] = swaps['target'] + [targetX59]

    initializations['kernel'] = initializations['kernel'][0:100]
    initializations['curve'] = initializations['curve'][0:100]
    swaps['kernel'] = swaps['kernel'][0:100]
    swaps['curve'] = swaps['curve'][0:100]
    swaps['target'] = swaps['target'][0:100]

    return initializations, swaps, kernelsValid, kernelsInvalid

def toInt(value):
    return int(value, 16)

def twosComplement(value):
    return value if value >= 0 else ((2 ** 256) + value)

def twosComplementInt8(value):
    return value if value >= 0 else (256 + value)

def encodeKernel(kernel):
    k = 0
    for point in kernel[1:]:
        k <<= 16
        k += point[1]
        k <<= 64
        k += point[0]
        k <<= 216
        k += floor(X216 * exp(- Integer(point[0]) / X60))
        k <<= 216
        k += floor(X216 * exp(- 16 + Integer(point[0]) / X60))

    l = 2 * (len(kernel) - 1)

    result = [0] * l
    while l != 0:
        l -= 1
        result[l] = k % X256
        k //= X256

    return result

def encodeKernelCompact(kernel):
    i = 0
    k = 0
    for point in kernel[1:]:
        k <<= 16
        k += point[1]
        k <<= 64
        k += point[0]
        i += 80
    if i % 256 != 0:
        k = k << (256 - (i % 256))
        i = i + (256 - (i % 256))
    l = i // 256
    kernelShortArray = [0] * l
    while l != 0:
        l -= 1
        kernelShortArray[l] = k % (2 ** 256)
        k //= (2 ** 256)

    return kernelShortArray

def encodeCurve(curve):
    encodedCurve = [0]*((len(curve) + 3) // 4)
    shift = 192
    index = 0
    for point in curve:
        encodedCurve[index // 4] += (point << shift)
        shift -= 64
        shift = shift % 256
        index += 1
    return encodedCurve

def amend(curve, targetX59):
    newCurve = [point for point in curve]
    point0 = newCurve[0]
    point1 = newCurve[1]
    if targetX59 <= min(point0, point1):
        return [max(point0, point1), min(point0, point1)]
    if targetX59 >= max(point0, point1):
        return [min(point0, point1), max(point0, point1)]
    index = 1
    while (True):
        if (min(point0, point1) < targetX59 < max(point0, point1)):
            point0 = point1
            index += 1
            if (index < len(newCurve)):
                point1 = curve[index]
            else:
                break
        else:
            break
    if (index < len(newCurve)):
        newCurve[index] = targetX59
        newCurve = newCurve[0: (index + 1)]
    else:
        newCurve += [targetX59]
    return newCurve

def getFunctionFromKernel(kernel):
    h = Symbol('h', real = True)
    args = []
    for k in range(len(kernel) - 1):
        c0 = Integer(kernel[k][1]) / X15
        c1 = Integer(kernel[k+1][1]) / X15
        b0 = Integer(kernel[k][0]) / X59
        b1 = Integer(kernel[k+1][0]) / X59
        if b1 != b0:
            args = args + [(
                c0 + ((c1 - c0) * (h - b0) / (b1 - b0)),
                And(b0 < h, h < b1)
            )]
    args = args + [(0, h < 0), (0, (Integer(kernel[-1][0]) / X59) < h), (0, True)]
    return Piecewise(*args), h

def getFunctionFromCurve(curve, kernel):
    zKernel, h = getFunctionFromKernel(kernel)
    args = []
    for k in range(len(curve), 1, -1):
        point0 = (curve[min(k, len(curve) - 1)] - X63) / Integer(X59)
        point1 = (curve[k - 1] - X63) / Integer(X59)
        point2 = (curve[k - 2] - X63) / Integer(X59)
        if point2 > point0:
            args = args + [(zKernel.subs(h, h - point1), And(point0 < h, h < point2))]
        else:
            args = args + [(zKernel.subs(h, point1 - h), And(point2 < h, h < point0))]
    point1 = min((curve[0] - X63) / Integer(X59), (curve[1] - X63) / Integer(X59))
    point2 = max((curve[0] - X63) / Integer(X59), (curve[1] - X63) / Integer(X59))
    args = args + [(0, h < point1), (0, point2 < h), (0, True)]
    return Piecewise(*args), h

def outgoing(curve, kernel, qMinX59, qMaxX59):
    if qMinX59 == qMaxX59:
        return Integer(0)
    
    integral = 0
    h = Symbol('h', real = True)

    if curve[-1] <= qMinX59:
        for kk in range(len(curve), 1, -1):
            point0 = curve[min(kk, len(curve) - 1)]
            point1 = curve[kk - 1]
            point2 = curve[kk - 2]
            if point0 < point2:
                begin = max(qMinX59, point0)
                end = min(qMaxX59, point2)
                if begin < end:
                    for ii in range(len(kernel) - 1):
                        c0 = Integer(kernel[ii][1]) / X15
                        c1 = Integer(kernel[ii + 1][1]) / X15
                        b0 = point1 + kernel[ii][0]
                        b1 = point1 + kernel[ii + 1][0]
                        limit0 = max(b0, begin)
                        limit1 = min(b1, end)
                        if limit0 < limit1:
                            f = ((c0 + ((c1 - c0) * (h - toRational(b0)) / (toRational(b1) - toRational(b0)))) * exp(- h / 2)).integrate(h)
                            integral += N(X216 * exp(-8) * (f.subs(h, toRational(limit1)) - f.subs(h, toRational(limit0))) / 2, 200)
        return floor(integral)
    
    if qMaxX59 <= curve[-1]:
        for kk in range(len(curve), 1, -1):
            point0 = curve[min(kk, len(curve) - 1)]
            point1 = curve[kk - 1]
            point2 = curve[kk - 2]
            if point2 < point0:
                begin = min(qMaxX59, point0)
                end = max(qMinX59, point2)
                if end < begin:
                    for ii in range(len(kernel) - 1):
                        c0 = Integer(kernel[ii][1]) / X15
                        c1 = Integer(kernel[ii + 1][1]) / X15
                        b0 = point1 - kernel[ii][0]
                        b1 = point1 - kernel[ii + 1][0]
                        limit0 = max(b1, end)
                        limit1 = min(b0, begin)
                        if limit0 < limit1:
                            f = ((c0 + ((c1 - c0) * (h - toRational(b0)) / (toRational(b1) - toRational(b0)))) * exp(+ h / 2)).integrate(h)
                            integral += N(X216 * exp(-8) * (f.subs(h, toRational(limit1)) - f.subs(h, toRational(limit0))) / 2, 200)
        return floor(integral)

def incoming(curve, kernel, qMinX59, qMaxX59):
    if qMinX59 == qMaxX59:
        return Integer(0)
    
    integral = 0
    h = Symbol('h', real = True)

    if curve[-1] <= qMinX59:
        for kk in range(len(curve), 1, -1):
            point0 = curve[min(kk, len(curve) - 1)]
            point1 = curve[kk - 1]
            point2 = curve[kk - 2]
            if point0 < point2:
                begin = max(qMinX59, point0)
                end = min(qMaxX59, point2)
                if begin < end:
                    for ii in range(len(kernel) - 1):
                        c0 = Integer(kernel[ii][1]) / X15
                        c1 = Integer(kernel[ii + 1][1]) / X15
                        b0 = point1 + kernel[ii][0]
                        b1 = point1 + kernel[ii + 1][0]
                        limit0 = max(b0, begin)
                        limit1 = min(b1, end)
                        if limit0 < limit1:
                            f = ((c0 + ((c1 - c0) * (h - toRational(b0)) / (toRational(b1) - toRational(b0)))) * exp(+ h / 2)).integrate(h)
                            integral += N(X216 * exp(-8) * (f.subs(h, toRational(limit1)) - f.subs(h, toRational(limit0))) / 2, 200)
        return floor(integral)
    
    if qMaxX59 <= curve[-1]:
        for kk in range(len(curve), 1, -1):
            point0 = curve[min(kk, len(curve) - 1)]
            point1 = curve[kk - 1]
            point2 = curve[kk - 2]
            if point2 < point0:
                begin = min(qMaxX59, point0)
                end = max(qMinX59, point2)
                if end < begin:
                    for ii in range(len(kernel) - 1):
                        c0 = Integer(kernel[ii][1]) / X15
                        c1 = Integer(kernel[ii + 1][1]) / X15
                        b0 = point1 - kernel[ii][0]
                        b1 = point1 - kernel[ii + 1][0]
                        limit0 = max(b1, end)
                        limit1 = min(b0, begin)
                        if limit0 < limit1:
                            f = ((c0 + ((c1 - c0) * (h - toRational(b0)) / (toRational(b1) - toRational(b0)))) * exp(- h / 2)).integrate(h)
                            integral += N(X216 * exp(-8) * (f.subs(h, toRational(limit1)) - f.subs(h, toRational(limit0))) / 2, 200)
        return floor(integral)

def getMaxIntegrals(kernel):
    lower = 1
    upper = kernel[-1][0] + 1
    zKernel, hKernel = getFunctionFromKernel(kernel)
    zOutgoing = piecewise_fold(zKernel.subs(hKernel, hKernel - (Integer(lower - (2 ** 63)) / (2 ** 59))) * exp(- hKernel / 2), evaluate = True)._eval_integral(hKernel)
    outgoingMax = floor(N((2 ** 216) * exp(-8) * exp(+ Integer(lower - (2 ** 63)) / (2 ** 60)) * (zOutgoing.subs(hKernel, Integer(upper - 2 ** 63) / (2 ** 59)) - zOutgoing.subs(hKernel, Integer(lower - 2 ** 63) / (2 ** 59))) / 2, 100))
    zIncoming = piecewise_fold(zKernel.subs(hKernel, hKernel - (Integer(lower - (2 ** 63)) / (2 ** 59))) * exp(+ hKernel / 2), evaluate = True)._eval_integral(hKernel)
    incomingMax = floor(N((2 ** 216) * exp(-8) * exp(- Integer(upper - (2 ** 63)) / (2 ** 60)) * (zIncoming.subs(hKernel, Integer(upper - 2 ** 63) / (2 ** 59)) - zIncoming.subs(hKernel, Integer(lower - 2 ** 63) / (2 ** 59))) / 2, 100))
    return outgoingMax, incomingMax