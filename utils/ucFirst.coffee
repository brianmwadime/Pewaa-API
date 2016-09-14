'use strict'
# ucFirst (typeof String):
# returns String with first character uppercased

module.exports = (string) ->
  word = string
  ucFirstWord = ''
  x = 0
  length = word.length
  while x < length
    # get the character's ASCII code
    character = word[x]
    # check to see if the character is capitalised/in uppercase using REGEX
    isUpperCase = /[A-Z]/g.test(character)
    asciiCode = character.charCodeAt(0)
    if asciiCode >= 65 and asciiCode <= 65 + 25 or asciiCode >= 97 and asciiCode <= 97 + 25
      # If the 1st letter is not in uppercase
      if !isUpperCase and x == 0
        # capitalize the letter, then convert it back to decimal value
        character = String.fromCharCode(asciiCode - 32)
      else if isUpperCase and x > 0
        # lowercase any of the letters that are not in the 1st postion that are in uppercase
        # lower case the letter, converting it back to decimal value
        character = String.fromCharCode(asciiCode + 32)
    ucFirstWord += character
    x++
  ucFirstWord