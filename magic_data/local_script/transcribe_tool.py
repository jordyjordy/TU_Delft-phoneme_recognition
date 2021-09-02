# -*- coding: utf-8 -*-
def getIntervalInfo(interval,cTextGrid):
    iStart = float(cTextGrid[interval][19:-1])
    iEnd   = float(cTextGrid[interval+1][19:-1])
    iText  = cTextGrid[interval+2][20:-3]
    return ( iStart, iEnd, iText)   # StartTime, EndTime, Text

def splitText(sentence):
    
    arr1split = sentence.split("？")

    arr2split = []
    for spl in arr1split:
        arr2split += spl.split("，")

    arr3split = []
    for spl in arr2split:
        arr3split += spl.split("！")

    arr4split = []
    for spl in arr3split:
        arr4split += spl.split("!")

    arr5split = []
    for spl in arr4split:
        arr5split += spl.split("。")
    
    arr6split = []
    for spl in arr5split:
        arr6split += spl.split("、")
    
    return arr6split

def findPhon(wholeBit, lexiconMapping):
    # Base case
    if len(wholeBit) == 0:
        return []
    # Recursion
    for i in range(len(wholeBit), 0, -1):   # for every letter in the given wholeBit
        bit = wholeBit[:i]                  # Take a substring of length i
        for translation in lexiconMapping:  # for every pair (word,phon) in the Lexicon
            word = translation[0]           # take the word from the pair
            if bit == word :                # if substring == word 
                return translation[1] + findPhon(wholeBit[i:],lexiconMapping)

    #print("\t !! Not Fully transformed !! ", wholeBit)
    #print("Deleting the first elem")

    return ["SPN"] # error failed to transform consider as Vocalized Noise


def transcribe(cTextGrid, file_to_transcribe):

    # Creating Lexicon Mappings of (words,phon)
    mappingLexion = []
    # for line in cLexicon:
    #     translation = line.split()
    #     word = translation[0]
    #     phon = translation[1:]
    #     mappingLexion.append((word,phon))
    #     #print(word, phon)

    # Creating the Text mappings (StartTime, EndTime, Text)
    mappingOfText = []
    for interval in range(15, len(cTextGrid), 4) :
        pair = getIntervalInfo(interval,cTextGrid)
        # print(pair)
        if ("[*]" in pair[2]) or ("[SONANT]" in pair[2]) or ("[ENS]" in pair[2]) or (len(pair[2]) == 0) or ("[ENS" in pair[2]) or ("[UNK]" in pair[2]) or ("[LAUGH]" in pair[2]):
            if ("[LAUGH]" in pair[2]):
                print("ignoring non vocal sounds")
                #mappingOfText.append((pair[0],pair[1],["[LAUGHTER]"]))
                continue
            else:
                #mappingOfText.append((pair[0],pair[1],["!SIL"]))
                #print("Ignoring !SIL by not appending it")
                continue
            continue
        else:
            mappingOfText.append((pair[0],pair[1],splitText(pair[2])))

    #print( mappingLexion, mappingOfText)
    # Word to Phoneme transform
    final_arr = []
    for pText in mappingOfText:
        arrText = pText[2]
        translationPhon = []
        #print(" > Started ", arrText)
        # if(isinstance(arrText,str)):
        #     translationPhon += tempTranslation
        # else:
        for bit in arrText:
            tempTranslation = bit
            translationPhon += tempTranslation
            #print("Final translation", tempTranslation)
        #print(arrText, translationPhon)
        final_arr.append((file_to_transcribe, pText[0],pText[1], pText[2], translationPhon))

    return final_arr


