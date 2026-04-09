# Copyright 2025, NoFeeSwap LLC - All rights reserved.
import pytest
from brownie import chain, accounts, Access, Nofeeswap, NofeeswapDelegatee, ERC20FixedSupply, MockHook, Operator, Deployer
from sympy import Float, Integer, floor, Float, log, ceiling
from eth_abi import encode
from Nofee import logTest, address0, mintSequence, burnSequence, swapSequence, keccak, toInt, twosComplementInt8, encodeKernelCompact, encodeCurve, checkPool, getPoolId, Pool

logPriceTickX59 = 57643193118714

feeSpacingSmallX59 = 288302457773874 # 0.05% fee
feeSpacingMediumX59 = 1731981530143823 # 0.3% fee
feeSpacingLargeX59 = 5793624167011548 # 1.0% fee

logPriceSpacingSmallX59 = 10 * logPriceTickX59
logPriceSpacingMediumX59 = 60 * logPriceTickX59
logPriceSpacingLargeX59 = 200 * logPriceTickX59

@pytest.fixture(autouse=True)
def deployment(fn_isolation):
    data = {
      "data": {
        "pool": {
          "swaps": [
            {
              "timestamp": "1678912283",
              "amount0": "-54.509378864783456676",
              "amount1": "33.242253417797630518",
              "amountUSD": "0",
              "sqrtPriceX96": "62040604693970055570430585511",
              "tick": "-4892"
            },
            {
              "timestamp": "1678775531",
              "amount0": "-57.81795786601035864",
              "amount1": "34.640546505642403813",
              "amountUSD": "0",
              "sqrtPriceX96": "61517740287547471606718514896",
              "tick": "-5061"
            },
            {
              "timestamp": "1680565919",
              "amount0": "76.043402474321969507",
              "amount1": "-60.666221196789015262",
              "amountUSD": "0",
              "sqrtPriceX96": "70247170591111610958930521314",
              "tick": "-2407"
            },
            {
              "timestamp": "1679052239",
              "amount0": "-59.310713518365242953",
              "amount1": "39.834502961221913901",
              "amountUSD": "0",
              "sqrtPriceX96": "65178972178033912232220596344",
              "tick": "-3905"
            },
            {
              "timestamp": "1682320439",
              "amount0": "92.606182040941344632",
              "amount1": "-70.734193848443043285",
              "amountUSD": "0",
              "sqrtPriceX96": "68572645574651464327596643691",
              "tick": "-2889"
            },
            {
              "timestamp": "1680408407",
              "amount0": "-68.816835334891482459",
              "amount1": "50.529455766498078977",
              "amountUSD": "0",
              "sqrtPriceX96": "68279359710514666118086256236",
              "tick": "-2975"
            },
            {
              "timestamp": "1685830499",
              "amount0": "-72.635743640091623424",
              "amount1": "61.700156989939424666",
              "amountUSD": "0",
              "sqrtPriceX96": "74086409375588533445890257061",
              "tick": "-1343"
            },
            {
              "timestamp": "1680671675",
              "amount0": "120.388036653223748021",
              "amount1": "-90.649930059991209637",
              "amountUSD": "0",
              "sqrtPriceX96": "68331198148189928298440113119",
              "tick": "-2960"
            },
            {
              "timestamp": "1690638359",
              "amount0": "-27.399274453519818744",
              "amount1": "26.92946443849332736",
              "amountUSD": "0",
              "sqrtPriceX96": "79200815273538349076797372668",
              "tick": "-7"
            },
            {
              "timestamp": "1678617395",
              "amount0": "65.593526294195490268",
              "amount1": "-41.746552346794388144",
              "amountUSD": "0",
              "sqrtPriceX96": "62921636829712932723975518222",
              "tick": "-4610"
            },
            {
              "timestamp": "1680508667",
              "amount0": "56.872507373832278899",
              "amount1": "-47.446546605528163594",
              "amountUSD": "0",
              "sqrtPriceX96": "72007965408379006723644826510",
              "tick": "-1912"
            },
            {
              "timestamp": "1680450023",
              "amount0": "-63.916009205456848946",
              "amount1": "54.261278607081279207",
              "amountUSD": "0",
              "sqrtPriceX96": "73804684257127403025414624897",
              "tick": "-1419"
            },
            {
              "timestamp": "1679944523",
              "amount0": "-79.564020449685141986",
              "amount1": "48.863485875822075388",
              "amountUSD": "0",
              "sqrtPriceX96": "62483613475812156545081201996",
              "tick": "-4749"
            },
            {
              "timestamp": "1678288559",
              "amount0": "75.92440696420160016",
              "amount1": "-59.514339239130816956",
              "amountUSD": "0",
              "sqrtPriceX96": "69640468512545404674370882254",
              "tick": "-2580"
            },
            {
              "timestamp": "1678414343",
              "amount0": "70.281293521579118964",
              "amount1": "-52.579481782817200357",
              "amountUSD": "0",
              "sqrtPriceX96": "68114385674494990459869616436",
              "tick": "-3024"
            },
            {
              "timestamp": "1677906731",
              "amount0": "-59.425043157402302798",
              "amount1": "50",
              "amountUSD": "0",
              "sqrtPriceX96": "73031764553457985524862278983",
              "tick": "-1629"
            },
            {
              "timestamp": "1689116375",
              "amount0": "-37.487185074377948479",
              "amount1": "24.499252038060191744",
              "amountUSD": "0",
              "sqrtPriceX96": "64682942932109638091294303137",
              "tick": "-4057"
            },
            {
              "timestamp": "1679657183",
              "amount0": "-69.85498395975341008",
              "amount1": "43.31114314577319271",
              "amountUSD": "0",
              "sqrtPriceX96": "62697738218582441637859558510",
              "tick": "-4681"
            },
            {
              "timestamp": "1681043939",
              "amount0": "-88.312905805834870068",
              "amount1": "74.637249348508154256",
              "amountUSD": "0",
              "sqrtPriceX96": "74117164819615903712892548841",
              "tick": "-1334"
            },
            {
              "timestamp": "1679877719",
              "amount0": "-151.446550536251246067",
              "amount1": "100.2",
              "amountUSD": "0",
              "sqrtPriceX96": "65576891078898324324829568633",
              "tick": "-3783"
            },
            {
              "timestamp": "1691376215",
              "amount0": "15.734665210861399604",
              "amount1": "-13.639468310957628818",
              "amountUSD": "0",
              "sqrtPriceX96": "73605496018483356820523309113",
              "tick": "-1473"
            },
            {
              "timestamp": "1678740143",
              "amount0": "-81.140782283986280775",
              "amount1": "46.754416228117505893",
              "amountUSD": "0",
              "sqrtPriceX96": "60522376729118073582953488868",
              "tick": "-5387"
            },
            {
              "timestamp": "1678562795",
              "amount0": "95.638483324261863992",
              "amount1": "-64.064150389512948915",
              "amountUSD": "0",
              "sqrtPriceX96": "64247741920724507197814311085",
              "tick": "-4192"
            },
            {
              "timestamp": "1679474099",
              "amount0": "92.606182040941344632",
              "amount1": "-59.492360420193360377",
              "amountUSD": "0",
              "sqrtPriceX96": "62964798601108234234188422738",
              "tick": "-4596"
            },
            {
              "timestamp": "1681043879",
              "amount0": "-72.890445745634979128",
              "amount1": "58.320656661407727707",
              "amountUSD": "0",
              "sqrtPriceX96": "71356504027468967947075574518",
              "tick": "-2093"
            },
            {
              "timestamp": "1681045007",
              "amount0": "63.202846903601969077",
              "amount1": "-52.830986866280159831",
              "amountUSD": "0",
              "sqrtPriceX96": "71967752666544624513347806485",
              "tick": "-1923"
            },
            {
              "timestamp": "1676931491",
              "amount0": "-49.11775858316895001",
              "amount1": "41.082031601870344784",
              "amountUSD": "0",
              "sqrtPriceX96": "73701332914503450753627107023",
              "tick": "-1447"
            },
            {
              "timestamp": "1690789127",
              "amount0": "25.995179778113929216",
              "amount1": "-25.081078120188246757",
              "amountUSD": "0",
              "sqrtPriceX96": "77240965962031101648878544435",
              "tick": "-509"
            },
            {
              "timestamp": "1681909619",
              "amount0": "-129.85044658153959885",
              "amount1": "106.132361866526252023",
              "amountUSD": "0",
              "sqrtPriceX96": "72809904492344332561273116389",
              "tick": "-1690"
            },
            {
              "timestamp": "1679629475",
              "amount0": "37.482883245204571711",
              "amount1": "-24.900830899410681927",
              "amountUSD": "0",
              "sqrtPriceX96": "64540794165824635071413575870",
              "tick": "-4101"
            },
            {
              "timestamp": "1689725411",
              "amount0": "34.0237556964754404",
              "amount1": "-30.942876587538083055",
              "amountUSD": "0",
              "sqrtPriceX96": "74737285823473560691549874172",
              "tick": "-1168"
            },
            {
              "timestamp": "1678656083",
              "amount0": "59.843868133081095994",
              "amount1": "-34.189683250285085246",
              "amountUSD": "0",
              "sqrtPriceX96": "59692463460544456590118128343",
              "tick": "-5663"
            },
            {
              "timestamp": "1682148119",
              "amount0": "92.792141094660352385",
              "amount1": "-75.255835340622458556",
              "amountUSD": "0",
              "sqrtPriceX96": "70625656285965028127622162343",
              "tick": "-2299"
            },
            {
              "timestamp": "1680449387",
              "amount0": "-104.927056544275437983",
              "amount1": "80.104764459489342673",
              "amountUSD": "0",
              "sqrtPriceX96": "69798241703798632652013400801",
              "tick": "-2535"
            },
            {
              "timestamp": "1691622659",
              "amount0": "-27.203993842135999112",
              "amount1": "24.323239270905073664",
              "amountUSD": "0",
              "sqrtPriceX96": "75487121069654324912640583610",
              "tick": "-968"
            },
            {
              "timestamp": "1689657359",
              "amount0": "-26.589536936108080505",
              "amount1": "19.432133088386940707",
              "amountUSD": "0",
              "sqrtPriceX96": "68146838397884476533250088044",
              "tick": "-3014"
            },
            {
              "timestamp": "1686390767",
              "amount0": "25.564861220195320871",
              "amount1": "-20.64978799549136896",
              "amountUSD": "0",
              "sqrtPriceX96": "70762324541752259714237277007",
              "tick": "-2261"
            },
            {
              "timestamp": "1677906455",
              "amount0": "100",
              "amount1": "-84.218016444740147244",
              "amountUSD": "0",
              "sqrtPriceX96": "71595061529348263625176645189",
              "tick": "-2027"
            },
            {
              "timestamp": "1681261487",
              "amount0": "103.831173803479689436",
              "amount1": "-78.440840926508071443",
              "amountUSD": "0",
              "sqrtPriceX96": "68487517011378614225775241767",
              "tick": "-2914"
            },
            {
              "timestamp": "1679381039",
              "amount0": "25.25437881495948049",
              "amount1": "-16.794520179739670349",
              "amountUSD": "0",
              "sqrtPriceX96": "64691522926908584260871267658",
              "tick": "-4055"
            },
            {
              "timestamp": "1677062027",
              "amount0": "26.480462610907651869",
              "amount1": "-24.451372374752649685",
              "amountUSD": "0",
              "sqrtPriceX96": "75566388597296058065349464911",
              "tick": "-947"
            },
            {
              "timestamp": "1685312783",
              "amount0": "77.268631802754735751",
              "amount1": "-64.470636234641784832",
              "amountUSD": "0",
              "sqrtPriceX96": "71716815507582213349313243413",
              "tick": "-1993"
            },
            {
              "timestamp": "1682890511",
              "amount0": "-97.247809434026759277",
              "amount1": "82.179787546332184576",
              "amountUSD": "0",
              "sqrtPriceX96": "74351108999361780926025854910",
              "tick": "-1271"
            },
            {
              "timestamp": "1679511359",
              "amount0": "-120.980677924926853326",
              "amount1": "80",
              "amountUSD": "0",
              "sqrtPriceX96": "65263523439683789273685436808",
              "tick": "-3879"
            },
            {
              "timestamp": "1678953083",
              "amount0": "-53.628960852736838714",
              "amount1": "33.478080805795431437",
              "amountUSD": "0",
              "sqrtPriceX96": "62767019960870781601640618423",
              "tick": "-4659"
            },
            {
              "timestamp": "1689663515",
              "amount0": "-70.731804012300775523",
              "amount1": "63.446182559402558423",
              "amountUSD": "0",
              "sqrtPriceX96": "77155179308176963752992823954",
              "tick": "-531"
            },
            {
              "timestamp": "1679942579",
              "amount0": "245.284194805",
              "amount1": "-154.950280165093299132",
              "amountUSD": "0",
              "sqrtPriceX96": "61079567117285431371255626776",
              "tick": "-5204"
            },
            {
              "timestamp": "1680132791",
              "amount0": "-74.492189032860048142",
              "amount1": "47.829684374452686614",
              "amountUSD": "0",
              "sqrtPriceX96": "63857954519471950285715546220",
              "tick": "-4314"
            },
            {
              "timestamp": "1681326575",
              "amount0": "-102.62255774445441194",
              "amount1": "79.097920791572043113",
              "amountUSD": "0",
              "sqrtPriceX96": "70249616924411422839977562993",
              "tick": "-2406"
            },
            {
              "timestamp": "1680348851",
              "amount0": "-83.904461098058699121",
              "amount1": "58.773853812978156513",
              "amountUSD": "0",
              "sqrtPriceX96": "66827443272387741801428369852",
              "tick": "-3405"
            },
            {
              "timestamp": "1678912211",
              "amount0": "109.447915119220214877",
              "amount1": "-66.444275517549892466",
              "amountUSD": "0",
              "sqrtPriceX96": "61085419773698623682852839537",
              "tick": "-5202"
            },
            {
              "timestamp": "1690900979",
              "amount0": "109.781363858133969488",
              "amount1": "-93.526166914275999744",
              "amountUSD": "0",
              "sqrtPriceX96": "69932779569225433079045165940",
              "tick": "-2497"
            },
            {
              "timestamp": "1677002795",
              "amount0": "-53.116785347739530553",
              "amount1": "48.807407627413087184",
              "amountUSD": "0",
              "sqrtPriceX96": "77477032353693984293504105987",
              "tick": "-448"
            },
            {
              "timestamp": "1678626875",
              "amount0": "60.682802552859836684",
              "amount1": "-37.240581278019732643",
              "amountUSD": "0",
              "sqrtPriceX96": "61840754895536471270579736696",
              "tick": "-4956"
            },
            {
              "timestamp": "1681058147",
              "amount0": "74.067936738453698484",
              "amount1": "-59.062551007974780745",
              "amountUSD": "0",
              "sqrtPriceX96": "70253503259579128131348753739",
              "tick": "-2405"
            },
            {
              "timestamp": "1680449591",
              "amount0": "-87.472401284617029664",
              "amount1": "70.567117168476278597",
              "amountUSD": "0",
              "sqrtPriceX96": "71825921516571731553685336028",
              "tick": "-1962"
            },
            {
              "timestamp": "1678650779",
              "amount0": "67.289946523286319238",
              "amount1": "-39.827301643305173175",
              "amountUSD": "0",
              "sqrtPriceX96": "60684795204363407859429186081",
              "tick": "-5334"
            },
            {
              "timestamp": "1681331627",
              "amount0": "-83.297363895341447536",
              "amount1": "67.98879886791628237",
              "amountUSD": "0",
              "sqrtPriceX96": "72203211183193882032546502178",
              "tick": "-1858"
            },
            {
              "timestamp": "1678672535",
              "amount0": "31.777065280748724265",
              "amount1": "-17.693136196274548572",
              "amountUSD": "0",
              "sqrtPriceX96": "59000443595569393936677297281",
              "tick": "-5897"
            },
            {
              "timestamp": "1678538531",
              "amount0": "97.380318090734197756",
              "amount1": "-69.15674676161720111",
              "amountUSD": "0",
              "sqrtPriceX96": "66107159266212048043790503326",
              "tick": "-3622"
            },
            {
              "timestamp": "1690635491",
              "amount0": "-33.175822544999042327",
              "amount1": "30.769328814229228603",
              "amountUSD": "0",
              "sqrtPriceX96": "77117574865559527817425726471",
              "tick": "-541"
            },
            {
              "timestamp": "1678926479",
              "amount0": "101.692292106381096498",
              "amount1": "-60",
              "amountUSD": "0",
              "sqrtPriceX96": "60299146482927968419296483942",
              "tick": "-5461"
            },
            {
              "timestamp": "1678590107",
              "amount0": "73.517271241776488398",
              "amount1": "-48.742588388709582221",
              "amountUSD": "0",
              "sqrtPriceX96": "64133301435829989394309469361",
              "tick": "-4228"
            },
            {
              "timestamp": "1678926503",
              "amount0": "-87.39002156540101275",
              "amount1": "52.408613818240529266",
              "amountUSD": "0",
              "sqrtPriceX96": "61805058762169262967763631855",
              "tick": "-4968"
            },
            {
              "timestamp": "1687654763",
              "amount0": "52.41037353014739577",
              "amount1": "-39.581105855969011348",
              "amountUSD": "0",
              "sqrtPriceX96": "67669435045982286017125171167",
              "tick": "-3155"
            },
            {
              "timestamp": "1676650643",
              "amount0": "-55.354793377752890609",
              "amount1": "42.249079815286677627",
              "amountUSD": "0",
              "sqrtPriceX96": "70523261977728908739472367829",
              "tick": "-2328"
            },
            {
              "timestamp": "1679657147",
              "amount0": "170.058625202455923779",
              "amount1": "-106.378468379033712547",
              "amountUSD": "0",
              "sqrtPriceX96": "61453233211878813644123632244",
              "tick": "-5082"
            },
            {
              "timestamp": "1687706399",
              "amount0": "93.229726682317809109",
              "amount1": "-62.473749951747598434",
              "amountUSD": "0",
              "sqrtPriceX96": "62787701683346059256135986822",
              "tick": "-4652"
            },
            {
              "timestamp": "1681601039",
              "amount0": "67.290448968105549765",
              "amount1": "-52.781282592600661303",
              "amountUSD": "0",
              "sqrtPriceX96": "69760290787353420660916493175",
              "tick": "-2546"
            },
            {
              "timestamp": "1678589999",
              "amount0": "-66.775403474499402425",
              "amount1": "45.252191054837963557",
              "amountUSD": "0",
              "sqrtPriceX96": "65548021115446039366598185880",
              "tick": "-3792"
            },
            {
              "timestamp": "1680338507",
              "amount0": "-66.586077345053282654",
              "amount1": "44.570007203667473542",
              "amountUSD": "0",
              "sqrtPriceX96": "65138631802153973265451115506",
              "tick": "-3917"
            },
            {
              "timestamp": "1691045687",
              "amount0": "-25.987420716956376267",
              "amount1": "22.767209994677030743",
              "amountUSD": "0",
              "sqrtPriceX96": "74671291613491638515666500178",
              "tick": "-1185"
            },
            {
              "timestamp": "1682846447",
              "amount0": "-117.519252229328614335",
              "amount1": "92.36516582253449832",
              "amountUSD": "0",
              "sqrtPriceX96": "71226671835844089178346271914",
              "tick": "-2130"
            },
            {
              "timestamp": "1678791671",
              "amount0": "-214.114045757631918876",
              "amount1": "138.848664269129458781",
              "amountUSD": "0",
              "sqrtPriceX96": "65507426204528547256524354709",
              "tick": "-3804"
            },
            {
              "timestamp": "1689440519",
              "amount0": "-36.537002451789128287",
              "amount1": "25.344672030684131328",
              "amountUSD": "0",
              "sqrtPriceX96": "66643585150668585267254188511",
              "tick": "-3460"
            },
            {
              "timestamp": "1690901015",
              "amount0": "-46.906317506878527974",
              "amount1": "38.486206125089579008",
              "amountUSD": "0",
              "sqrtPriceX96": "72910039660405856886735796672",
              "tick": "-1663"
            },
            {
              "timestamp": "1681442567",
              "amount0": "38.660947742319058916",
              "amount1": "-31.386814477450298924",
              "amountUSD": "0",
              "sqrtPriceX96": "71292230753357040715710923463",
              "tick": "-2111"
            },
            {
              "timestamp": "1689661151",
              "amount0": "-66.899334979181889722",
              "amount1": "53.002113693121155135",
              "amountUSD": "0",
              "sqrtPriceX96": "72247036721768233674635990324",
              "tick": "-1845"
            },
            {
              "timestamp": "1678791695",
              "amount0": "131.961073626108242177",
              "amount1": "-85.911023143925260174",
              "amountUSD": "0",
              "sqrtPriceX96": "63013918593311623434585159555",
              "tick": "-4580"
            },
            {
              "timestamp": "1679016299",
              "amount0": "-68.194235758267718674",
              "amount1": "44.106025341686716509",
              "amountUSD": "0",
              "sqrtPriceX96": "64034365160668008316757878209",
              "tick": "-4259"
            },
            {
              "timestamp": "1686205403",
              "amount0": "45.630165278863327232",
              "amount1": "-38.374776392024689736",
              "amountUSD": "0",
              "sqrtPriceX96": "72375910392878767433340743707",
              "tick": "-1810"
            },
            {
              "timestamp": "1681043795",
              "amount0": "-94.156396070165657038",
              "amount1": "71.851844456717515807",
              "amountUSD": "0",
              "sqrtPriceX96": "69680714751598782352450213681",
              "tick": "-2569"
            },
            {
              "timestamp": "1678181327",
              "amount0": "69.740317147535424835",
              "amount1": "-57.328982733547428654",
              "amountUSD": "0",
              "sqrtPriceX96": "71367830758257548719060344184",
              "tick": "-2090"
            }
          ],
          "burns": [
            {
              "timestamp": "1692856451",
              "amount0": "50.248460544798835792",
              "amount1": "351.054722332760216911",
              "amount": "1013918632249847647549",
              "amountUSD": "0",
              "tickLower": "-10000",
              "tickUpper": "0"
            },
            {
              "timestamp": "1686367655",
              "amount0": "19.548329803783434876",
              "amount1": "283.515252784173798891",
              "amount": "1715799325214808507432",
              "amountUSD": "0",
              "tickLower": "-5800",
              "tickUpper": "-1600"
            },
            {
              "timestamp": "1681604747",
              "amount0": "0",
              "amount1": "238.532326937995915306",
              "amount": "3568882715345606891841",
              "amountUSD": "1180.675347012604950883971935762975",
              "tickLower": "-4400",
              "tickUpper": "-2800"
            }
          ],
          "mints": [
            {
              "timestamp": "1676380091",
              "amount0": "180.505851317503573117",
              "amount1": "245.703383258980194573",
              "amount": "1013918632249847647549",
              "amountUSD": "1314.440578615765490530627072119537",
              "tickLower": "-10000",
              "tickUpper": "0"
            },
            {
              "timestamp": "1677906203",
              "amount0": "0",
              "amount1": "300",
              "amount": "1715799325214808507432",
              "amountUSD": "1396.07462169645672316816032413726",
              "tickLower": "-5800",
              "tickUpper": "-1600"
            },
            {
              "timestamp": "1680411107",
              "amount0": "36.000358858040374608",
              "amount1": "211.559994832301078971",
              "amount": "3568882715345606891841",
              "amountUSD": "0",
              "tickLower": "-4400",
              "tickUpper": "-2800"
            }
          ],
          "collects": []
        }
      }
    }

    data = data['data']['pool']

    swaps = data['swaps']
    burns = data['burns']
    mints = data['mints']

    for swap in swaps:
        swap['action'] = 'swap'
        swap['timestamp'] = Integer(swap['timestamp'])
        swap['amount0'] = Float(swap['amount0'])
        swap['amount1'] = Float(swap['amount1'])
        swap['amountUSD'] = Float(swap['amountUSD'])
        swap['sqrtPriceX96'] = Integer(swap['sqrtPriceX96'])
        swap['tick'] = Integer(swap['tick'])
    for burn in burns:
        burn['action'] = 'burn'
        burn['timestamp'] = Integer(burn['timestamp'])
        burn['amount0'] = Float(burn['amount0'])
        burn['amount1'] = Float(burn['amount1'])
        burn['amountUSD'] = Float(burn['amountUSD'])
        burn['amount'] = Integer(burn['amount'])
        burn['tickLower'] = Integer(burn['tickLower'])
        burn['tickUpper'] = Integer(burn['tickUpper'])
    for mint in mints:
        mint['action'] = 'mint'
        mint['timestamp'] = Integer(mint['timestamp'])
        mint['amount0'] = Float(mint['amount0'])
        mint['amount1'] = Float(mint['amount1'])
        mint['amountUSD'] = Float(mint['amountUSD'])
        mint['amount'] = Integer(mint['amount'])
        mint['tickLower'] = Integer(mint['tickLower'])
        mint['tickUpper'] = Integer(mint['tickUpper'])

    data = swaps + burns + mints
    data = sorted(data, key=lambda x: x['timestamp'])

    root = accounts[0]
    owner = accounts[1]
    other = accounts[2]
    deployer = Deployer.deploy(root, {'from': root})
    delegatee = deployer.addressOf(1)
    nofeeswap = deployer.addressOf(2)
    deployer.create3(
        1,
        NofeeswapDelegatee.bytecode + encode(
            ['address'],
            [nofeeswap]
        ).hex(), 
        {'from': root}
    )
    deployer.create3(
        2,
        Nofeeswap.bytecode + encode(
            ['address', 'address'],
            [delegatee, root.address]
        ).hex(), 
        {'from': root}
    )
    delegatee = NofeeswapDelegatee.at(delegatee)
    nofeeswap = Nofeeswap.at(nofeeswap)
    access = Access.deploy({'from': root})
    hook = MockHook.deploy({'from': root})
    operator = Operator.deploy(nofeeswap, address0, address0, address0, {'from': root})

    protocolGrowthPortion = 0
    poolGrowthPortion = (1 << 47) // 5

    nofeeswap.dispatch(delegatee.modifyProtocol.encode_input(
        (poolGrowthPortion << 208) + (protocolGrowthPortion << 160) + int(root.address, 16)
    ), {'from': root})

    return data, root, owner, other, nofeeswap, delegatee, access, hook, operator, poolGrowthPortion, protocolGrowthPortion

def test_swapData(deployment, request, worker_id):
    logTest(request, worker_id)
    
    data, root, owner, other, nofeeswap, delegatee, access, hook, operator, poolGrowthPortion, protocolGrowthPortion = deployment

    nofeeswap.setOperator(operator, True, {'from': root})

    token0 = ERC20FixedSupply.deploy("ERC20_0", "ERC20_0", 2**128, root, {'from': root})
    token1 = ERC20FixedSupply.deploy("ERC20_1", "ERC20_1", 2**128, root, {'from': root})
    token0.approve(operator, 2**128, {'from': root})
    token1.approve(operator, 2**128, {'from': root})
    if toInt(token0.address) > toInt(token1.address):
        token0, token1 = token1, token0
    tag0 = toInt(token0.address)
    tag1 = toInt(token1.address)

    kernel = [
        [0, 0],
        # [feeSpacingLargeX59, 0],
        # [feeSpacingLargeX59, 2 ** 15],
        [logPriceSpacingLargeX59, 2 ** 15]
    ]

    spacing = kernel[-1][0]

    logOffset = 0

    sqrtPriceX96 = 67254909186229727392878661970
    logPrice = int(floor((2 ** 60) * log(sqrtPriceX96 / Integer(2 ** 96))))
    logPriceOffsetted = logPrice - logOffset + (1 << 63)

    lower = logPrice - (logPrice % spacing) - logOffset + (1 << 63)
    upper = lower + spacing
    curve = [lower, upper, logPriceOffsetted]

    # initialization
    unsaltedPoolId = (1 << 188) + (twosComplementInt8(logOffset) << 180) + (0b00000000000000000000 << 160) + 0
    poolId = getPoolId(owner.address, unsaltedPoolId)

    pool = Pool(
        logOffset,
        curve,
        kernel,
        Integer(protocolGrowthPortion) / (1 << 47),
        Integer(poolGrowthPortion) / (1 << 47),
        50
    )
    tx = nofeeswap.dispatch(
      delegatee.initialize.encode_input(
        unsaltedPoolId,
        tag0,
        tag1,
        poolGrowthPortion,
        encodeKernelCompact(kernel),
        encodeCurve(curve),
        b""
      ),
      {'from': owner}
    )

    ##############################

    numberOfSwaps = 0
    gasLogPrice = 0
    gasIncoming = 0
    gasOutgoing = 0

    for n in range(len(data)):
        d = data[n]

        if d['action'] == 'mint':
            # modifyPosition
            qMin = int(logPriceTickX59 * d['tickLower'])
            qMax = int(logPriceTickX59 * d['tickUpper'])
            shares = int(d['amount'])
            tagShares = keccak(['uint256', 'int256', 'int256'], [poolId, qMin, qMax])

            deadline = 2 ** 32 - 1
            hookData = b""

            pool.modifyPosition(qMin, qMax, shares)
            tx = nofeeswap.unlock(
                operator,
                mintSequence(nofeeswap, token0, token1, tagShares, poolId, qMin, qMax, shares, hookData, deadline),
                {'from': root}
            )

        if d['action'] == 'burn':
            # modifyPosition
            qMin = int(logPriceTickX59 * d['tickLower'])
            qMax = int(logPriceTickX59 * d['tickUpper'])
            shares = int(d['amount'])
            tagShares = keccak(['uint256', 'int256', 'int256'], [poolId, qMin, qMax])

            deadline = 2 ** 32 - 1
            hookData = b""

            pool.modifyPosition(qMin, qMax, -shares)
            tx = nofeeswap.unlock(
                operator,
                burnSequence(token0, token1, owner, tagShares, poolId, qMin, qMax, shares, hookData, deadline),
                {'from': root}
            )

        if d['action'] == 'swap':
            # swap with log price
            amountSpecified = - (1 << 120)
            logPriceLimit = int(floor((2 ** 60) * log(d['sqrtPriceX96'] / Integer(2 ** 96))))
            zeroForOne = 2

            amount0 = token0.balanceOf(nofeeswap)
            amount1 = token1.balanceOf(nofeeswap)
            tx = nofeeswap.unlock(
                operator,
                swapSequence(nofeeswap, token0, token1, root, poolId, amountSpecified, logPriceLimit, zeroForOne, hookData, deadline),
                {'from': root}
            )
            amount0 = token0.balanceOf(nofeeswap) - amount0
            amount1 = token1.balanceOf(nofeeswap) - amount1
            gasLogPrice += tx.gas_used

            chain.undo()

            (incoming, outgoing) = (amount0, amount1) if (amount0 >= 0 and amount1 <= 0) else (amount1, amount0)

            # swap with incoming
            amountSpecified = incoming
            logPriceLimit = (2 ** 64) if logPrice < int(floor((2 ** 60) * log(d['sqrtPriceX96'] / Integer(2 ** 96)))) else (- 2 ** 64)
            zeroForOne = 2

            tx = nofeeswap.unlock(
                operator,
                swapSequence(nofeeswap, token0, token1, root, poolId, amountSpecified, logPriceLimit, zeroForOne, hookData, deadline),
                {'from': root}
            )
            gasIncoming += tx.gas_used
            chain.undo()

            # swap with outgoing
            amountSpecified = outgoing
            logPriceLimit = (2 ** 64) if logPrice < int(floor((2 ** 60) * log(d['sqrtPriceX96'] / Integer(2 ** 96)))) else (- 2 ** 64)
            zeroForOne = 2

            amount0 = token0.balanceOf(nofeeswap)
            amount1 = token1.balanceOf(nofeeswap)
            tx = nofeeswap.unlock(
                operator,
                swapSequence(nofeeswap, token0, token1, root, poolId, amountSpecified, logPriceLimit, zeroForOne, hookData, deadline),
                {'from': root}
            )
            amount0 = token0.balanceOf(nofeeswap) - amount0
            amount1 = token1.balanceOf(nofeeswap) - amount1
            gasOutgoing += tx.gas_used

            _target = (toInt(tx.events['Swap']['data'].hex()) >> 128) % (2 ** 64)
            _overshoot = (toInt(tx.events['Swap']['data'].hex()) >> 192)

            _amount0 = pool.amount0
            _amount1 = pool.amount1
            g, g_minus, g_plus = pool.swap(_target, _overshoot)
            assert g_minus <= g
            assert g_plus <= g
            _amount0 = pool.amount0 - _amount0
            _amount1 = pool.amount1 - _amount1

            assert ceiling(_amount0) == amount0
            assert ceiling(_amount1) == amount1

            checkPool(nofeeswap, access, poolId, pool)

            numberOfSwaps = numberOfSwaps + 1
            logPrice = int(floor((2 ** 60) * log(d['sqrtPriceX96'] / Integer(2 ** 96))))

    print(numberOfSwaps)
    print(gasLogPrice / numberOfSwaps)
    print(gasIncoming / numberOfSwaps)
    print(gasOutgoing / numberOfSwaps)