# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import os
import time
from sympy import Integer, Symbol, Piecewise, And, floor, piecewise_fold, exp, N, oo
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

PUSH0 = 0
PUSH10 = 1
PUSH16 = 2
PUSH32 = 3
NEG = 4
ADD = 5
SUB = 6
MIN = 7
MAX = 8
MUL = 9
DIV = 10
DIV_ROUND_DOWN = 11
DIV_ROUND_UP = 12
LT = 13
EQ = 14
LTEQ = 15
ISZERO = 16
AND = 17
OR = 18
XOR = 19
JUMPDEST = 20
JUMP = 21
READ_TRANSIENT_BALANCE = 22
READ_BALANCE_OF_NATIVE = 23
READ_BALANCE_OF_ERC20 = 24
READ_BALANCE_OF_MULTITOKEN = 25
READ_ALLOWANCE_ERC20 = 26
READ_ALLOWANCE_PERMIT2 = 27
READ_ALLOWANCE_ERC6909 = 28
READ_IS_OPERATOR_ERC6909 = 29
READ_IS_APPROVED_FOR_ALL_ERC1155 = 30
READ_DOUBLE_BALANCE = 31
WRAP_NATIVE = 32
UNWRAP_NATIVE = 33
PERMIT_PERMIT2 = 34
PERMIT_BATCH_PERMIT2 = 35
TRANSFER_NATIVE = 36
TRANSFER_FROM_PAYER_ERC20 = 37
TRANSFER_FROM_PAYER_PERMIT2 = 38
TRANSFER_FROM_PAYER_ERC6909 = 39
SAFE_TRANSFER_FROM_PAYER_ERC1155 = 40
CLEAR = 41
TAKE_TOKEN = 42
TAKE_ERC6909 = 43
TAKE_ERC1155 = 44
SYNC_TOKEN = 45
SYNC_MULTITOKEN = 46
SETTLE = 47
TRANSFER_TRANSIENT_BALANCE = 48
TRANSFER_TRANSIENT_BALANCE_FROM_PAYER = 49
MODIFY_SINGLE_BALANCE = 50
MODIFY_DOUBLE_BALANCE = 51
SWAP = 52
MODIFY_POSITION = 53
DONATE = 54
QUOTE_SWAP = 55
QUOTE_MODIFY_POSITION = 56
QUOTE_DONATE = 57
QUOTER_TRANSIENT_ACCESS = 58
REVERT = 59

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

class Pool:
    def __init__(
        self,
        logOffset,
        curve,
        kernel,
        protocolGrowthPortion,
        poolGrowthPortion,
        numberOfIntervals
    ):
        self.protocolGrowthPortion = protocolGrowthPortion
        self.poolGrowthPortion = poolGrowthPortion
        self.logOffset = Integer(logOffset)
        self.curve = curve
        self.kernel = kernel
        self.amount0 = 0
        self.amount1 = 0
        self.poolAccrued0 = 0
        self.poolAccrued1 = 0
        self.protocolAccrued0 = 0
        self.protocolAccrued1 = 0

        lower = min(curve[0], curve[1])
        upper = max(curve[0], curve[1])
        spacing = upper - lower
        minLogPrice = max(spacing - ((- lower) % spacing), lower - numberOfIntervals * spacing)
        maxLogPrice = ((2 ** 64) - 1) - (((2 ** 64) - 1) % spacing) + (lower % spacing)
        if maxLogPrice > ((2 ** 64) - 1):
            maxLogPrice -= spacing
        maxLogPrice = min(maxLogPrice, upper + numberOfIntervals * spacing)

        self.growth = {}
        self.sharesTotal = {}
        for logPrice in range(minLogPrice, maxLogPrice, spacing):
            self.growth[logPrice] = Integer(1)
            self.sharesTotal[logPrice] = Integer(0)

    def modifyPosition(
        self,
        logPriceMin,
        logPriceMax,
        shares
    ):
        logPriceMinOffsetted = int(logPriceMin - self.logOffset * (1 << 59) + (1 << 63))
        logPriceMaxOffsetted = int(logPriceMax - self.logOffset * (1 << 59) + (1 << 63))
        current = self.curve[-1]
        lower = min(self.curve[0], self.curve[1])
        upper = max(self.curve[0], self.curve[1])
        spacing = upper - lower

        outgoingMax, incomingMax = getMaxIntegrals(self.kernel)
        
        for logPrice in range(logPriceMinOffsetted, logPriceMaxOffsetted, spacing):
            growth = self.growth[logPrice]
            _shares = shares
            sqrtOffset = exp(self.logOffset / 2)

            if upper <= logPrice:
                self.amount0 += _shares * growth * (outgoing([logPrice + spacing, logPrice], self.kernel, logPrice, logPrice + spacing) / outgoingMax) / sqrtOffset
            if logPrice + spacing <= lower:
                self.amount1 += _shares * growth * (outgoing([logPrice, logPrice + spacing], self.kernel, logPrice, logPrice + spacing) / outgoingMax) * sqrtOffset
            if (lower <= logPrice) and (logPrice + spacing <= upper):
                self.amount0 += _shares * growth * (outgoing(self.curve, self.kernel, current, upper) / outgoingMax) / sqrtOffset
                self.amount1 += _shares * growth * (outgoing(self.curve, self.kernel, lower, current) / outgoingMax) * sqrtOffset

            self.sharesTotal[logPrice] += shares

    def swap(
        self,
        target,
        overshoot
    ):
        current = self.curve[-1]
        if target == current:
            return Integer(1), Integer(1), Integer(1)
        zeroForOne = target < current
        outgoingMax, incomingMax = getMaxIntegrals(self.kernel)

        lower = min(self.curve[0], self.curve[1])
        upper = max(self.curve[0], self.curve[1])
        spacing = upper - lower

        g = Integer(0)
        g_minus = Integer(0)
        g_plus = Integer(0)

        while (current != target):
            growth = self.growth[lower]
            shares = self.sharesTotal[lower]
            sqrtOffset = exp(self.logOffset / 2)

            _target = max(target, lower) if zeroForOne else min(target, upper)

            self.amount0 -= shares * growth * (outgoing(self.curve, self.kernel, current, upper) / outgoingMax) / sqrtOffset
            self.amount1 -= shares * growth * (outgoing(self.curve, self.kernel, lower, current) / outgoingMax) * sqrtOffset

            if _target != target:
                if zeroForOne:
                    g = (outgoing(self.curve, self.kernel, current, upper) + incoming(self.curve, self.kernel, lower, current)) / outgoing([upper, lower], self.kernel, lower, upper)
                    self.amount0 += shares * g * growth * (outgoing([upper, lower], self.kernel, lower, upper) / outgoingMax) / sqrtOffset
                    self.growth[lower] = (1 + (g - 1) * (1 - self.protocolGrowthPortion) * (1 - self.poolGrowthPortion)) * self.growth[lower]
                    self.curve = [lower - spacing, lower]
                    current = lower
                    upper = lower
                    lower = lower - spacing
                else:
                    g = (outgoing(self.curve, self.kernel, lower, current) + incoming(self.curve, self.kernel, current, upper)) / outgoing([lower, upper], self.kernel, lower, upper)
                    self.amount1 += shares * g * growth * (outgoing([lower, upper], self.kernel, lower, upper) / outgoingMax) * sqrtOffset
                    self.growth[lower] = (1 + (g - 1) * (1 - self.protocolGrowthPortion) * (1 - self.poolGrowthPortion)) * self.growth[lower]
                    self.curve = [upper + spacing, upper]
                    current = upper
                    lower = upper
                    upper = upper + spacing
            else:
                _curve = amend(amend(self.curve, overshoot), target)

                denominator0 = outgoing(_curve, self.kernel, target, upper)
                denominator1 = outgoing(_curve, self.kernel, lower, target)

                if zeroForOne:
                    numerator0 = outgoing(self.curve, self.kernel, current, upper) + incoming(self.curve, self.kernel, target, current)
                    numerator1 = outgoing(self.curve, self.kernel, lower, target)
                else:
                    numerator0 = outgoing(self.curve, self.kernel, target, upper)
                    numerator1 = outgoing(self.curve, self.kernel, lower, current) + incoming(self.curve, self.kernel, current, target)

                if denominator0 == 0:
                    g0 = +oo
                else:
                    g0 = numerator0 / denominator0

                if denominator1 == 0:
                    g1 = +oo
                else:
                    g1 = numerator1 / denominator1

                g = min(g0, g1)

                self.amount0 += shares * g * growth * (denominator0 / outgoingMax) / sqrtOffset
                self.amount1 += shares * g * growth * (denominator1 / outgoingMax) * sqrtOffset

                if (overshoot != upper) and not(zeroForOne and (overshoot == target)):
                    _curve_plus = amend(amend(self.curve, overshoot + 1), target)

                    denominator0 = outgoing(_curve_plus, self.kernel, target, upper)
                    denominator1 = outgoing(_curve_plus, self.kernel, lower, target)

                    if denominator0 == 0:
                        g0 = Integer(1)
                    else:
                        g0 = numerator0 / denominator0

                    if denominator1 == 0:
                        g1 = Integer(1)
                    else:
                        g1 = numerator1 / denominator1

                    g_plus = min(g0, g1)

                if (overshoot != lower) and not(not(zeroForOne) and (overshoot == target)):
                    _curve_minus = amend(amend(self.curve, overshoot - 1), target)

                    denominator0 = outgoing(_curve_minus, self.kernel, target, upper)
                    denominator1 = outgoing(_curve_minus, self.kernel, lower, target)

                    if denominator0 == 0:
                        g0 = Integer(1)
                    else:
                        g0 = numerator0 / denominator0

                    if denominator1 == 0:
                        g1 = Integer(1)
                    else:
                        g1 = numerator1 / denominator1

                    g_plus = min(g0, g1)

                self.curve = _curve
                self.growth[lower] = (1 + (g - 1) * (1 - self.protocolGrowthPortion) * (1 - self.poolGrowthPortion)) * self.growth[lower]
                current = target

        return g, g_minus, g_plus

def getGrowthMultiplier(nofeeswap, access, poolId, lower, upper, logPrice):
    growthMultiplier = access._readGrowthMultiplier(nofeeswap, poolId, logPrice)

    if growthMultiplier != 0:
        return growthMultiplier
    else:
        if logPrice <= lower:
            return (2 ** 208) * exp(+ Integer(logPrice - (2 ** 63)) / (2 ** 60)) / (1 - exp(- Integer(upper - lower) / (2 ** 60)))
        else:
            return (2 ** 208) * exp(- Integer(logPrice - (2 ** 63)) / (2 ** 60)) / (1 - exp(- Integer(upper - lower) / (2 ** 60)))

def checkPool(nofeeswap, access, poolId, pool):
    curve = pool.curve
    lower = min(curve[0], curve[1])
    upper = max(curve[0], curve[1])
    current = curve[-1]
    spacing = upper - lower
    minLogPrice = min(list(pool.growth.keys()))
    maxLogPrice = max(list(pool.growth.keys()))

    staticParamsStoragePointerExtension, staticParamsStoragePointer, logPriceCurrent, sharesTotal, growth, integral0, integral1 = access._readDynamicParams(nofeeswap, poolId)
    curveArray = list(access._readCurve(nofeeswap, poolId, logPriceCurrent).return_value)

    sharesTotalAll = {}
    growthAll = {}

    sharesTotalAll[lower] = sharesTotal
    growthAll[lower] = growth

    for logPrice in range(lower - spacing, minLogPrice - 1, - spacing):
        sharesTotalAll[logPrice] = sharesTotalAll[logPrice + spacing] - access._readSharesDelta(nofeeswap, poolId, logPrice + spacing)
        growthAll[logPrice] = floor(((getGrowthMultiplier(nofeeswap, access, poolId, lower, upper, logPrice + spacing) - getGrowthMultiplier(nofeeswap, access, poolId, lower, upper, logPrice)) * exp(- Integer(logPrice + spacing - (2 ** 63)) / (2 ** 60))) / (2 ** 97))

    for logPrice in range(lower + spacing, maxLogPrice + 1, + spacing):
        sharesTotalAll[logPrice] = sharesTotalAll[logPrice - spacing] + access._readSharesDelta(nofeeswap, poolId, logPrice)
        growthAll[logPrice] = floor(((getGrowthMultiplier(nofeeswap, access, poolId, lower, upper, logPrice) - getGrowthMultiplier(nofeeswap, access, poolId, lower, upper, logPrice + spacing)) * exp(+ Integer(logPrice - (2 ** 63)) / (2 ** 60))) / (2 ** 97))

    for logPrice in range(minLogPrice, maxLogPrice, spacing):
        assert abs(floor((1 << 111) * pool.growth[logPrice]) - growthAll[logPrice]) <= 2 ** 10
        assert pool.sharesTotal[logPrice] == sharesTotalAll[logPrice]

    assert abs(integral0 - outgoing(pool.curve, pool.kernel, current, upper)) <= 2 ** 64
    assert abs(integral1 - outgoing(pool.curve, pool.kernel, lower, current)) <= 2 ** 64
    assert current == logPriceCurrent
    assert curveArray == encodeCurve(pool.curve)

def mintSequence(nofeeswap, token0, token1, tagShares, poolId, qMin, qMax, shares, hookData, deadline):
    sharesSlot = 1

    successSlot = 2

    amount0Slot = 3
    amount1Slot = 4

    successSlotTransfer0 = 7
    successSlotTransfer1 = 8

    valueSlotSettle0 = 9
    successSlotSettle0 = 10
    resultSlotSettle0 = 11

    valueSlotSettle1 = 12
    successSlotSettle1 = 13
    resultSlotSettle1 = 14

    sharesSuccessSlot = 15

    logOffset = ((poolId >> 180) % 256)
    if logOffset >= 128:
        logOffset -= 256

    lower = qMin + (1 << 63) - (logOffset * (1 << 59))
    upper = qMax + (1 << 63) - (logOffset * (1 << 59))

    sequence = [0] * 9
    sequence[0] = encode_packed(
      ['uint8', 'int256', 'uint8'],
      [PUSH32, shares, sharesSlot]
    )
    sequence[1] = encode_packed(
      ['uint8', 'uint256', 'uint64', 'uint64', 'uint8', 'uint8', 'uint8', 'uint8', 'uint16', 'bytes'],
      [MODIFY_POSITION, poolId, lower, upper, sharesSlot, successSlot, amount0Slot, amount1Slot, len(hookData), hookData]
    )
    sequence[2] = encode_packed(
      ['uint8', 'address'],
      [SYNC_TOKEN, token0.address]
    )
    sequence[3] = encode_packed(
      ['uint8', 'address', 'uint8', 'address', 'uint8', 'uint8'],
      [TRANSFER_FROM_PAYER_ERC20, token0.address, amount0Slot, nofeeswap.address, successSlotTransfer0, 0]
    )
    sequence[4] = encode_packed(
      ['uint8', 'uint8', 'uint8', 'uint8'],
      [SETTLE, valueSlotSettle0, successSlotSettle0, resultSlotSettle0]
    )
    sequence[5] = encode_packed(
      ['uint8', 'address'],
      [SYNC_TOKEN, token1.address]
    )
    sequence[6] = encode_packed(
      ['uint8', 'address', 'uint8', 'address', 'uint8', 'uint8'],
      [TRANSFER_FROM_PAYER_ERC20, token1.address, amount1Slot, nofeeswap.address, successSlotTransfer1, 0]
    )
    sequence[7] = encode_packed(
      ['uint8', 'uint8', 'uint8', 'uint8'],
      [SETTLE, valueSlotSettle1, successSlotSettle1, resultSlotSettle1]
    )
    sequence[8] = encode_packed(
      ['uint8', 'uint256', 'uint8', 'uint8'],
      [MODIFY_SINGLE_BALANCE, tagShares, sharesSlot, sharesSuccessSlot]
    )
    
    return encode_packed(['uint32'] + ['bytes'] * len(sequence), [deadline] + sequence)

def burnSequence(token0, token1, payer, tagShares, poolId, qMin, qMax, shares, hookData, deadline):
    sharesSlot = 1

    successSlot = 2

    amount0Slot = 3
    amount1Slot = 4

    successSlotSettle0 = 10
    successSlotSettle1 = 13

    sharesSuccessSlot = 15

    logOffset = ((poolId >> 180) % 256)
    if logOffset >= 128:
        logOffset -= 256

    lower = qMin + (1 << 63) - (logOffset * (1 << 59))
    upper = qMax + (1 << 63) - (logOffset * (1 << 59))

    sequence = [0] * 7
    sequence[0] = encode_packed(
      ['uint8', 'int256', 'uint8'],
      [PUSH32, -shares, sharesSlot]
    )
    sequence[1] = encode_packed(
      ['uint8', 'uint256', 'uint64', 'uint64', 'uint8', 'uint8', 'uint8', 'uint8', 'uint16', 'bytes'],
      [MODIFY_POSITION, poolId, lower, upper, sharesSlot, successSlot, amount0Slot, amount1Slot, len(hookData), hookData]
    )
    sequence[2] = encode_packed(
      ['uint8', 'uint8', 'uint8'],
      [NEG, amount0Slot, amount0Slot]
    )
    sequence[3] = encode_packed(
      ['uint8', 'uint8', 'uint8'],
      [NEG, amount1Slot, amount1Slot]
    )
    sequence[4] = encode_packed(
      ['uint8', 'address', 'address', 'uint8', 'uint8'],
      [TAKE_TOKEN, token0.address, payer.address, amount0Slot, successSlotSettle0]
    )
    sequence[5] = encode_packed(
      ['uint8', 'address', 'address', 'uint8', 'uint8'],
      [TAKE_TOKEN, token1.address, payer.address, amount1Slot, successSlotSettle1]
    )
    sequence[6] = encode_packed(
      ['uint8', 'uint256', 'uint8', 'uint8'],
      [MODIFY_SINGLE_BALANCE, tagShares, sharesSlot, sharesSuccessSlot]
    )

    return encode_packed(['uint32'] + ['bytes'] * len(sequence), [deadline] + sequence)

def swapSequence(nofeeswap, token0, token1, payer, poolId, amountSpecified, limit, zeroForOne, hookData, deadline):
    successSlot = 2

    amount0Slot = 3
    amount1Slot = 4

    successSlotTransfer0 = 7
    successSlotTransfer1 = 8

    valueSlotSettle0 = 9
    successSlotSettle0 = 10
    resultSlotSettle0 = 11

    valueSlotSettle1 = 12
    successSlotSettle1 = 13
    resultSlotSettle1 = 14

    amountSpecifiedSlot = 15
    zeroSlot = 100
    logicSlot = 200

    logOffset = ((poolId >> 180) % 256)
    if logOffset >= 128:
        logOffset -= 256

    limitOffsetted = limit + (1 << 63) - (logOffset * (1 << 59))
    if limitOffsetted < 0:
        limitOffsetted = 0
    if limitOffsetted >= (2 ** 64):
        limitOffsetted = (2 ** 64) - 1

    sequence = [0] * 27
    sequence[0] = encode_packed(
      ['uint8', 'int256', 'uint8'],
      [PUSH32, amountSpecified, amountSpecifiedSlot]
    )
    sequence[1] = encode_packed(
      [
        'uint8',
        'uint256',
        'uint8',
        'uint64',
        'uint8',
        'uint8',
        'uint8',
        'uint8',
        'uint8',
        'uint16',
        'bytes'
      ],
      [
        SWAP,
        poolId,
        amountSpecifiedSlot,
        limitOffsetted,
        zeroForOne,
        zeroSlot,
        successSlot,
        amount0Slot,
        amount1Slot,
        len(hookData),
        hookData
      ]
    )
    sequence[2] = encode_packed(
      ['uint8', 'uint16', 'uint8'],
      [0, 0, 0]
    )
    sequence[3] = encode_packed(
      ['uint8'],
      [REVERT]
    )
    sequence[4] = encode_packed(
      ['uint8'],
      [JUMPDEST]
    )
    sequence[2] = encode_packed(
      ['uint8', 'uint16', 'uint8'],
      [JUMP, sum([len(action) for action in sequence[0:4]]), successSlot]
    )
    sequence[5] = encode_packed(
      ['uint8', 'uint8', 'uint8', 'uint8'],
      [LT, zeroSlot, amount0Slot, logicSlot]
    )
    sequence[6] = encode_packed(
      ['uint8', 'uint16', 'uint8'],
      [0, 0, 0]
    )
    sequence[7] = encode_packed(
      ['uint8', 'uint8', 'uint8'],
      [NEG, amount0Slot, amount0Slot]
    )
    sequence[8] = encode_packed(
      ['uint8', 'address', 'address', 'uint8', 'uint8'],
      [TAKE_TOKEN, token0.address, payer.address, amount0Slot, successSlotSettle0]
    )
    sequence[9] = encode_packed(
      ['uint8'],
      [JUMPDEST]
    )
    sequence[6] = encode_packed(
      ['uint8', 'uint16', 'uint8'],
      [JUMP, sum([len(action) for action in sequence[0:9]]), logicSlot]
    )
    sequence[10] = encode_packed(
      ['uint8', 'uint8', 'uint8'],
      [ISZERO, logicSlot, logicSlot]
    )
    sequence[11] = encode_packed(
      ['uint8', 'uint16', 'uint8'],
      [0, 0, 0]
    )
    sequence[12] = encode_packed(
      ['uint8', 'address'],
      [SYNC_TOKEN, token0.address]
    )
    sequence[13] = encode_packed(
      ['uint8', 'address', 'uint8', 'address', 'uint8', 'uint8'],
      [TRANSFER_FROM_PAYER_ERC20, token0.address, amount0Slot, nofeeswap.address, successSlotTransfer0, 0]
    )
    sequence[14] = encode_packed(
      ['uint8', 'uint8', 'uint8', 'uint8'],
      [SETTLE, valueSlotSettle0, successSlotSettle0, resultSlotSettle0]
    )
    sequence[15] = encode_packed(
      ['uint8'],
      [JUMPDEST]
    )
    sequence[11] = encode_packed(
      ['uint8', 'uint16', 'uint8'],
      [JUMP, sum([len(action) for action in sequence[0:15]]), logicSlot]
    )

    sequence[16] = encode_packed(
      ['uint8', 'uint8', 'uint8', 'uint8'],
      [LT, zeroSlot, amount1Slot, logicSlot]
    )
    sequence[17] = encode_packed(
      ['uint8', 'uint16', 'uint8'],
      [0, 0, 0]
    )
    sequence[18] = encode_packed(
      ['uint8', 'uint8', 'uint8'],
      [NEG, amount1Slot, amount1Slot]
    )
    sequence[19] = encode_packed(
      ['uint8', 'address', 'address', 'uint8', 'uint8'],
      [TAKE_TOKEN, token1.address, payer.address, amount1Slot, successSlotSettle1]
    )
    sequence[20] = encode_packed(
      ['uint8'],
      [JUMPDEST]
    )
    sequence[17] = encode_packed(
      ['uint8', 'uint16', 'uint8'],
      [JUMP, sum([len(action) for action in sequence[0:20]]), logicSlot]
    )
    sequence[21] = encode_packed(
      ['uint8', 'uint8', 'uint8'],
      [ISZERO, logicSlot, logicSlot]
    )
    sequence[22] = encode_packed(
      ['uint8', 'uint16', 'uint8'],
      [0, 0, 0]
    )
    sequence[23] = encode_packed(
      ['uint8', 'address'],
      [SYNC_TOKEN, token1.address]
    )
    sequence[24] = encode_packed(
      ['uint8', 'address', 'uint8', 'address', 'uint8', 'uint8'],
      [TRANSFER_FROM_PAYER_ERC20, token1.address, amount1Slot, nofeeswap.address, successSlotTransfer1, 0]
    )
    sequence[25] = encode_packed(
      ['uint8', 'uint8', 'uint8', 'uint8'],
      [SETTLE, valueSlotSettle1, successSlotSettle1, resultSlotSettle1]
    )
    sequence[26] = encode_packed(
      ['uint8'],
      [JUMPDEST]
    )
    sequence[22] = encode_packed(
      ['uint8', 'uint16', 'uint8'],
      [JUMP, sum([len(action) for action in sequence[0:26]]), logicSlot]
    )

    return encode_packed(['uint32'] + ['bytes'] * len(sequence), [deadline] + sequence)

def donateSequence(nofeeswap, token0, token1, poolId, shares, hookData, deadline):
    sharesSlot = 1

    successSlot = 2

    amount0Slot = 3
    amount1Slot = 4

    successSlotTransfer0 = 7
    successSlotTransfer1 = 8

    valueSlotSettle0 = 9
    successSlotSettle0 = 10
    resultSlotSettle0 = 11

    valueSlotSettle1 = 12
    successSlotSettle1 = 13
    resultSlotSettle1 = 14

    sequence = [0] * 8
    sequence[0] = encode_packed(
      ['uint8', 'int256', 'uint8'],
      [PUSH32, shares, sharesSlot]
    )
    sequence[1] = encode_packed(
      ['uint8', 'uint256', 'uint8', 'uint8', 'uint8', 'uint8', 'uint16', 'bytes'],
      [DONATE, poolId, sharesSlot, successSlot, amount0Slot, amount1Slot, len(hookData), hookData]
    )
    sequence[2] = encode_packed(
      ['uint8', 'address'],
      [SYNC_TOKEN, token0.address]
    )
    sequence[3] = encode_packed(
      ['uint8', 'address', 'uint8', 'address', 'uint8', 'uint8'],
      [TRANSFER_FROM_PAYER_ERC20, token0.address, amount0Slot, nofeeswap.address, successSlotTransfer0, 0]
    )
    sequence[4] = encode_packed(
      ['uint8', 'uint8', 'uint8', 'uint8'],
      [SETTLE, valueSlotSettle0, successSlotSettle0, resultSlotSettle0]
    )
    sequence[5] = encode_packed(
      ['uint8', 'address'],
      [SYNC_TOKEN, token1.address]
    )
    sequence[6] = encode_packed(
      ['uint8', 'address', 'uint8', 'address', 'uint8', 'uint8'],
      [TRANSFER_FROM_PAYER_ERC20, token1.address, amount1Slot, nofeeswap.address, successSlotTransfer1, 0]
    )
    sequence[7] = encode_packed(
      ['uint8', 'uint8', 'uint8', 'uint8'],
      [SETTLE, valueSlotSettle1, successSlotSettle1, resultSlotSettle1]
    )
    return encode_packed(['uint32'] + ['bytes'] * len(sequence), [deadline] + sequence)

def collectSequence(token0, token1, tag0, tag1, payer, amount0, amount1, deadline):
    amount0Slot = 3
    amount1Slot = 4

    successSlotSettle0 = 10
    successSlotSettle1 = 13
    
    sequence = [0] * 8
    sequence[0] = encode_packed(
      ['uint8', 'int256', 'uint8'],
      [PUSH32, amount0, amount0Slot]
    )
    sequence[1] = encode_packed(
      ['uint8', 'int256', 'uint8'],
      [PUSH32, amount1, amount1Slot]
    )
    sequence[2] = encode_packed(
      ['uint8', 'uint256', 'uint8', 'uint8'],
      [MODIFY_SINGLE_BALANCE, tag0, amount0Slot, 0]
    )
    sequence[3] = encode_packed(
      ['uint8', 'uint256', 'uint8', 'uint8'],
      [MODIFY_SINGLE_BALANCE, tag1, amount1Slot, 0]
    )
    sequence[4] = encode_packed(
      ['uint8', 'uint8', 'uint8'],
      [NEG, amount0Slot, amount0Slot]
    )
    sequence[5] = encode_packed(
      ['uint8', 'uint8', 'uint8'],
      [NEG, amount1Slot, amount1Slot]
    )
    sequence[6] = encode_packed(
      ['uint8', 'address', 'address', 'uint8', 'uint8'],
      [TAKE_TOKEN, token0.address, payer.address, amount0Slot, successSlotSettle0]
    )
    sequence[7] = encode_packed(
      ['uint8', 'address', 'address', 'uint8', 'uint8'],
      [TAKE_TOKEN, token1.address, payer.address, amount1Slot, successSlotSettle1]
    )
    
    return encode_packed(['uint32'] + ['bytes'] * len(sequence), [deadline] + sequence)