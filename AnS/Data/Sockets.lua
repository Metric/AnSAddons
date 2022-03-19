-- a list of all bonus ids that grant sockets in some form

local Ans = select(2, ...);
local crafted = {
    [21846] = 1,
    [21847] = 1,
    [21848] = 1,
    [21863] = 1,
    [21864] = 1,
    [21865] = 1,
    [21869] = 1,
    [21870] = 1,
    [21871] = 1,
    [21873] = 1,
    [21875] = 1,
    [23506] = 1,
    [23507] = 1,
    [23508] = 1,
    [23509] = 1,
    [23510] = 1,
    [23511] = 1,
    [23512] = 1,
    [23513] = 1,
    [23514] = 1,
    [23515] = 1,
    [23516] = 1,
    [23517] = 1,
    [23518] = 1,
    [23519] = 1,
    [23526] = 1,
    [23531] = 1,
    [23532] = 1,
    [23533] = 1,
    [23534] = 1,
    [23535] = 1,
    [23536] = 1,
    [23563] = 1,
    [23564] = 1,
    [23565] = 1,
    [24249] = 1,
    [24250] = 1,
    [24251] = 1,
    [24255] = 1,
    [24256] = 1,
    [24257] = 1,
    [24259] = 1,
    [24261] = 1,
    [24262] = 1,
    [24263] = 1,
    [24264] = 1,
    [24266] = 1,
    [24267] = 1,
    [25685] = 1,
    [25686] = 1,
    [25687] = 1,
    [25689] = 1,
    [25690] = 1,
    [25691] = 1,
    [25692] = 1,
    [25693] = 1,
    [25694] = 1,
    [25695] = 1,
    [25696] = 1,
    [25697] = 1,
    [28483] = 1,
    [28484] = 1,
    [28485] = 1,
    [29489] = 1,
    [29490] = 1,
    [29491] = 1,
    [29492] = 1,
    [29493] = 1,
    [29494] = 1,
    [29495] = 1,
    [29496] = 1,
    [29497] = 1,
    [29498] = 1,
    [29499] = 1,
    [29500] = 1,
    [29515] = 1,
    [29516] = 1,
    [29517] = 1,
    [29519] = 1,
    [29520] = 1,
    [29521] = 1,
    [29522] = 1,
    [29523] = 1,
    [29524] = 1,
    [30032] = 1,
    [30034] = 1,
    [30036] = 1,
    [30038] = 1,
    [30040] = 1,
    [30042] = 1,
    [30044] = 1,
    [30046] = 1,
    [30074] = 1,
    [30076] = 1,
    [32461] = 1,
    [32472] = 1,
    [32473] = 1,
    [32474] = 1,
    [32475] = 1,
    [32476] = 1,
    [32478] = 1,
    [32479] = 1,
    [32480] = 1,
    [32494] = 1,
    [32495] = 1,
    [32508] = 1,
    [32776] = 1,
    [33122] = 1,
    [33173] = 1,
    [33204] = 1,
    [34353] = 1,
    [34354] = 1,
    [34355] = 1,
    [34356] = 1,
    [34357] = 1,
    [34358] = 1,
    [34359] = 1,
    [34360] = 1,
    [34364] = 1,
    [34365] = 1,
    [34366] = 1,
    [34367] = 1,
    [34369] = 1,
    [34370] = 1,
    [34371] = 1,
    [34372] = 1,
    [34373] = 1,
    [34374] = 1,
    [34375] = 1,
    [34376] = 1,
    [34377] = 1,
    [34378] = 1,
    [34379] = 1,
    [34380] = 1,
    [34847] = 1,
    [35181] = 1,
    [35182] = 1,
    [35183] = 1,
    [35184] = 1,
    [35185] = 1,
    [41386] = 1,
    [41387] = 1,
    [41388] = 1,
    [41984] = 1,
    [42336] = 1,
    [42337] = 1,
    [42338] = 1,
    [42339] = 1,
    [42341] = 1,
    [42395] = 1,
    [42413] = 1,
    [42418] = 1,
    [42549] = 1,
    [42550] = 1,
    [42551] = 1,
    [42552] = 1,
    [42553] = 1,
    [42554] = 1,
    [42555] = 1,
    [42642] = 1,
    [42643] = 1,
    [42644] = 1,
    [42645] = 1,
    [42646] = 1,
    [42647] = 1,
    [43244] = 1,
    [43245] = 1,
    [43246] = 1,
    [43247] = 1,
    [43248] = 1,
    [43249] = 1,
    [43250] = 1,
    [43251] = 1,
    [43252] = 1,
    [43253] = 1,
    [43482] = 1,
    [43498] = 1,
    [43582] = 1,
    [43583] = 1,
    [43584] = 1,
    [43585] = 1,
    [43586] = 1,
    [43587] = 1,
    [43588] = 1,
    [43590] = 1,
    [43591] = 1,
    [43592] = 1,
    [43593] = 1,
    [43594] = 1,
    [43595] = 1,
    [44063] = 1,
    [44949] = 1,
    [45550] = 1,
    [45551] = 1,
    [45552] = 1,
    [45553] = 1,
    [45554] = 1,
    [45555] = 1,
    [45556] = 1,
    [45557] = 1,
    [45558] = 1,
    [45559] = 1,
    [45560] = 1,
    [45561] = 1,
    [45562] = 1,
    [45563] = 1,
    [45564] = 1,
    [45565] = 1,
    [45566] = 1,
    [45567] = 1,
    [47570] = 1,
    [47571] = 1,
    [47572] = 1,
    [47573] = 1,
    [47574] = 1,
    [47575] = 1,
    [47576] = 1,
    [47577] = 1,
    [47579] = 1,
    [47580] = 1,
    [47581] = 1,
    [47582] = 1,
    [47583] = 1,
    [47584] = 1,
    [47585] = 1,
    [47586] = 1,
    [47587] = 1,
    [47588] = 1,
    [47589] = 1,
    [47590] = 1,
    [47591] = 1,
    [47592] = 1,
    [47593] = 1,
    [47594] = 1,
    [47595] = 1,
    [47596] = 1,
    [47597] = 1,
    [47598] = 1,
    [47599] = 1,
    [47600] = 1,
    [47601] = 1,
    [47602] = 1,
    [47603] = 1,
    [47604] = 1,
    [47605] = 1,
    [47606] = 1,
    [49890] = 1,
    [49891] = 1,
    [49892] = 1,
    [49893] = 1,
    [49894] = 1,
    [49895] = 1,
    [49896] = 1,
    [49897] = 1,
    [49898] = 1,
    [49899] = 1,
    [49900] = 1,
    [49901] = 1,
    [49902] = 1,
    [49903] = 1,
    [49904] = 1,
    [49905] = 1,
    [49906] = 1,
    [49907] = 1,
    [52318] = 1,
    [52319] = 1,
    [52320] = 1,
    [52321] = 1,
    [52322] = 1,
    [52323] = 1,
    [52348] = 1,
    [52350] = 1,
    [54503] = 1,
    [54504] = 1,
    [54505] = 1,
    [54506] = 1,
    [55031] = 1,
    [55058] = 1,
    [55059] = 1,
    [55060] = 1,
    [55061] = 1,
    [55062] = 1,
    [55063] = 1,
    [55069] = 1,
    [55070] = 1,
    [56536] = 1,
    [56537] = 1,
    [56538] = 1,
    [56539] = 1,
    [56549] = 1,
    [56561] = 1,
    [56562] = 1,
    [56563] = 1,
    [56564] = 1,
    [58483] = 1,
    [59359] = 1,
    [59448] = 1,
    [59449] = 1,
    [59453] = 1,
    [59455] = 1,
    [59456] = 1,
    [59458] = 1,
    [64644] = 1,
    [68775] = 1,
    [68776] = 1,
    [68777] = 1,
    [69852] = 1,
    [69936] = 1,
    [69937] = 1,
    [69938] = 1,
    [69939] = 1,
    [69941] = 1,
    [69942] = 1,
    [69943] = 1,
    [69944] = 1,
    [69945] = 1,
    [69946] = 1,
    [69947] = 1,
    [69948] = 1,
    [69949] = 1,
    [69950] = 1,
    [69951] = 1,
    [69952] = 1,
    [69953] = 1,
    [69954] = 1,
    [71980] = 1,
    [71981] = 1,
    [71982] = 1,
    [71983] = 1,
    [71984] = 1,
    [71985] = 1,
    [71986] = 1,
    [71987] = 1,
    [71988] = 1,
    [71989] = 1,
    [71990] = 1,
    [71991] = 1,
    [71992] = 1,
    [71993] = 1,
    [71994] = 1,
    [71995] = 1,
    [71996] = 1,
    [71997] = 1,
    [77530] = 1,
    [77533] = 1,
    [77534] = 1,
    [77535] = 1,
    [77536] = 1,
    [77537] = 1,
    [77538] = 1,
    [77539] = 1,
    [82437] = 1,
    [82438] = 1,
    [82439] = 1,
    [82440] = 1,
    [82975] = 1,
    [82976] = 1,
    [82977] = 1,
    [82978] = 1,
    [82979] = 1,
    [82980] = 1,
    [85787] = 1,
    [85788] = 1,
    [85821] = 1,
    [85822] = 1,
    [85823] = 1,
    [85824] = 1,
    [85825] = 1,
    [85826] = 1,
    [85827] = 1,
    [85828] = 1,
    [85829] = 1,
    [85830] = 1,
    [85831] = 1,
    [85840] = 1,
    [85849] = 1,
    [85850] = 1,
    [86311] = 1,
    [86312] = 1,
    [86313] = 1,
    [86314] = 1,
    [87402] = 1,
    [87403] = 1,
    [87404] = 1,
    [87405] = 1,
    [87406] = 1,
    [87407] = 1,
    [93428] = 1,
    [93429] = 1,
    [93430] = 1,
    [93431] = 1,
    [93432] = 1,
    [93433] = 1,
    [93453] = 1,
    [93454] = 1,
    [93455] = 1,
    [93456] = 1,
    [93457] = 1,
    [93458] = 1,
    [93459] = 1,
    [93460] = 1,
    [93461] = 1,
    [93462] = 1,
    [93463] = 1,
    [93464] = 1,
    [93466] = 1,
    [93467] = 1,
    [93468] = 1,
    [93469] = 1,
    [93470] = 1,
    [93472] = 1,
    [93473] = 1,
    [93475] = 1,
    [93476] = 1,
    [93477] = 1,
    [93478] = 1,
    [93479] = 1,
    [93488] = 1,
    [93489] = 1,
    [93490] = 1,
    [93491] = 1,
    [93494] = 1,
    [93495] = 1,
    [93496] = 1,
    [93497] = 1,
    [93498] = 1,
    [93499] = 1,
    [93500] = 1,
    [93501] = 1,
    [93502] = 1,
    [93503] = 1,
    [93504] = 1,
    [93505] = 1,
    [93507] = 1,
    [93509] = 1,
    [93511] = 1,
    [93513] = 1,
    [93515] = 1,
    [93517] = 1,
    [93519] = 1,
    [93521] = 1,
    [93523] = 1,
    [93525] = 1,
    [93527] = 1,
    [93528] = 1,
    [93529] = 1,
    [93530] = 1,
    [93531] = 1,
    [93532] = 1,
    [93533] = 1,
    [93534] = 1,
    [93535] = 1,
    [93538] = 1,
    [93539] = 1,
    [93540] = 1,
    [93541] = 1,
    [93542] = 1,
    [93543] = 1,
    [93544] = 1,
    [93545] = 1,
    [93546] = 1,
    [93550] = 1,
    [93551] = 1,
    [93552] = 1,
    [93553] = 1,
    [93554] = 1,
    [93555] = 1,
    [93556] = 1,
    [93557] = 1,
    [93558] = 1,
    [93559] = 1,
    [93566] = 1,
    [93567] = 1,
    [93569] = 1,
    [93570] = 1,
    [93571] = 1,
    [93572] = 1,
    [93573] = 1,
    [93574] = 1,
    [93575] = 1,
    [93576] = 1,
    [93579] = 1,
    [93580] = 1,
    [93581] = 1,
    [93582] = 1,
    [93583] = 1,
    [93584] = 1,
    [93585] = 1,
    [93586] = 1,
    [93587] = 1,
    [93588] = 1,
    [93589] = 1,
    [93590] = 1,
    [93591] = 1,
    [93592] = 1,
    [93593] = 1,
    [93594] = 1,
    [93615] = 1,
    [93616] = 1,
    [93617] = 1,
    [93618] = 1,
    [93619] = 1,
    [93620] = 1,
    [93621] = 1,
    [93622] = 1,
    [93623] = 1,
    [93624] = 1,
    [94263] = 1,
    [94264] = 1,
    [94265] = 1,
    [94266] = 1,
    [94267] = 1,
    [94268] = 1,
    [94269] = 1,
    [94270] = 1,
    [94271] = 1,
    [94272] = 1,
    [94273] = 1,
    [94274] = 1,
    [94275] = 1,
    [94276] = 1,
    [94277] = 1,
    [94278] = 1,
    [94279] = 1,
    [94280] = 1,
    [98599] = 1,
    [98600] = 1,
    [98601] = 1,
    [98602] = 1,
    [98603] = 1,
    [98604] = 1,
    [98605] = 1,
    [98606] = 1,
    [98607] = 1,
    [98608] = 1,
    [98609] = 1,
    [98610] = 1,
    [98611] = 1,
    [98612] = 1,
    [98613] = 1,
    [98614] = 1,
    [98615] = 1,
    [98616] = 1,
    [98763] = 1,
    [98764] = 1,
    [98765] = 1,
    [98766] = 1,
    [98767] = 1,
    [98768] = 1,
    [98784] = 1,
    [98785] = 1,
    [98786] = 1,
    [98787] = 1,
    [98788] = 1,
    [98789] = 1,
    [98790] = 1,
    [98791] = 1,
    [98792] = 1,
    [98793] = 1,
    [98794] = 1,
    [98795] = 1,
    [98797] = 1,
    [98798] = 1,
    [98799] = 1,
    [98800] = 1,
    [98801] = 1,
    [98802] = 1,
    [98803] = 1,
    [98805] = 1,
    [98806] = 1,
    [98807] = 1,
    [98808] = 1,
    [98809] = 1,
    [98814] = 1,
    [98815] = 1,
    [98816] = 1,
    [98817] = 1,
    [98820] = 1,
    [98821] = 1,
    [98822] = 1,
    [98823] = 1,
    [98824] = 1,
    [98825] = 1,
    [98826] = 1,
    [98827] = 1,
    [98828] = 1,
    [98829] = 1,
    [98830] = 1,
    [98831] = 1,
    [98833] = 1,
    [98834] = 1,
    [98835] = 1,
    [98836] = 1,
    [98837] = 1,
    [98838] = 1,
    [98839] = 1,
    [98840] = 1,
    [98841] = 1,
    [98842] = 1,
    [98843] = 1,
    [98844] = 1,
    [98845] = 1,
    [98846] = 1,
    [98847] = 1,
    [98848] = 1,
    [98849] = 1,
    [98850] = 1,
    [98851] = 1,
    [98854] = 1,
    [98855] = 1,
    [98856] = 1,
    [98857] = 1,
    [98858] = 1,
    [98859] = 1,
    [98860] = 1,
    [98861] = 1,
    [98862] = 1,
    [98865] = 1,
    [98866] = 1,
    [98867] = 1,
    [98868] = 1,
    [98869] = 1,
    [98870] = 1,
    [98871] = 1,
    [98872] = 1,
    [98873] = 1,
    [98874] = 1,
    [98881] = 1,
    [98882] = 1,
    [98884] = 1,
    [98885] = 1,
    [98886] = 1,
    [98887] = 1,
    [98888] = 1,
    [98889] = 1,
    [98890] = 1,
    [98891] = 1,
    [98894] = 1,
    [98895] = 1,
    [98896] = 1,
    [98897] = 1,
    [98898] = 1,
    [98899] = 1,
    [98900] = 1,
    [98901] = 1,
    [98902] = 1,
    [98903] = 1,
    [98904] = 1,
    [98905] = 1,
    [98906] = 1,
    [98907] = 1,
    [98908] = 1,
    [98909] = 1,
    [98921] = 1,
    [98922] = 1,
    [98923] = 1,
    [98924] = 1,
    [98925] = 1,
    [98926] = 1,
    [98927] = 1,
    [98928] = 1,
    [98929] = 1,
    [98930] = 1,
    [130223] = 1,
    [130224] = 1,
    [130225] = 1,
    [130226] = 1,
    [130227] = 1,
    [130228] = 1,
    [130229] = 1,
    [130230] = 1,
    [130231] = 1,
    [130233] = 1,
    [130234] = 1,
    [130235] = 1,
    [130236] = 1,
    [130237] = 1,
    [130238] = 1,
    [130239] = 1,
    [130240] = 1,
    [130241] = 1,
    [130242] = 1,
    [130243] = 1,
    [130244] = 1,
    [136711] = 1,
    [136712] = 1,
    [136713] = 1,
    [146666] = 1,
    [146667] = 1,
    [146668] = 1,
    [146669] = 1,
    [151587] = 1,
    [151588] = 1,
    [151589] = 1,
    [151590] = 1,
    [153683] = 1,
    [153684] = 1,
    [153685] = 1,
    [153686] = 1,
    [153687] = 1,
    [153688] = 1,
    [153689] = 1,
    [153690] = 1,
    [166519] = 1,
    [166520] = 1,
    [166521] = 1,
    [166522] = 1,
    [166523] = 1,
    [166524] = 1,
    [168674] = 1,
    [168675] = 1,
    [168676] = 1,
    [168677] = 1,
    [168678] = 1,
    [168679] = 1,
    [168680] = 1,
    [168681] = 1,
    [168682] = 1,
    [168683] = 1,
    [168684] = 1,
    [168685] = 1,
    [168686] = 1,
    [168687] = 1,
    [168688] = 1,
    [168701] = 1,
    [168702] = 1,
    [168703] = 1,
    [168704] = 1,
    [168705] = 1,
    [168706] = 1,
    [168707] = 1,
    [168708] = 1,
    [168709] = 1,
    [168710] = 1,
    [168711] = 1,
    [168712] = 1,
    [168713] = 1,
    [168714] = 1,
    [168715] = 1,
    [168716] = 1,
    [168717] = 1,
    [168718] = 1,
    [168719] = 1,
    [168720] = 1,
    [168721] = 1,
    [168722] = 1,
    [168723] = 1,
    [168724] = 1,
    [168725] = 1,
    [168726] = 1,
    [168727] = 1,
    [168728] = 1,
    [168729] = 1,
    [168730] = 1,
    [168731] = 1,
    [168732] = 1,
    [168733] = 1,
    [168734] = 1,
    [168735] = 1,
    [168736] = 1,
    [168737] = 1,
    [168738] = 1,
    [168739] = 1,
    [170386] = 1,
    [170387] = 1,
    [170388] = 1,
    [170389] = 1,
    [170390] = 1,
    [170391] = 1,
    [170432] = 1,
    [170433] = 1,
    [170434] = 1,
    [170435] = 1,
    [170436] = 1,
    [170437] = 1,
    [170438] = 1,
    [170439] = 1,
    [170440] = 1,
    [170441] = 1,
    [170442] = 1,
    [170443] = 1,
    [170456] = 1,
    [170457] = 1,
    [170458] = 1,
    [170459] = 1,
    [170460] = 1,
    [170461] = 1,
    [171075] = 1,
    [171076] = 1,
    [171077] = 1,
    [171085] = 1,
    [171087] = 1,
    [171088] = 1,
    [173131] = 1,
    [173132] = 1,
    [173133] = 1,
    [173134] = 1,
    [173135] = 1,
    [173136] = 1,
    [173137] = 1,
    [173138] = 1,
    [173140] = 1,
    [173141] = 1,
    [173142] = 1,
    [173143] = 1,
    [173144] = 1,
    [173145] = 1,
    [173146] = 1,
    [173147] = 1
};

Ans.Data.SocketCrafted = function(id)
    return crafted[id] ~= nil;
end

Ans.Data.SocketBonus = function(num)
    return num == 523 or num == 563 or num == 564 or num == 565 
            or num == 572 or num == 608 or num == 1808 or num == 3475
            or num == 3522 or num == 4802 or num == 6514 or num == 6672
            or num == 6935 or num == 7576 or num == 7580;
end

