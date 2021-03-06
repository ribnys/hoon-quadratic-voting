::
:: Hoon implementation of anonymous quadratic voting
:: Quadratic voting is a voting system where voters have the ability to vote for
:: multiple options and can indicate the strength of their preference for each
:: option.  Voters are assigned some number of voting credits and can "spend"
:: voting credits among the different voting options, with the cost in voting
:: credits being the square of the number of votes made for each option.
:: This generator contains a core with arms for implementing anonymous
:: quadratic voting and some sample code showing how anonymous voting could be
:: implemented.  The procedure allows anonymous voting as long as voters are
:: not conspiring with the pollmaker (even then, only some information is
:: leaked under certain conditions).  To start a poll, the pollmaker generates
:: an anonymous quadratic poll (anon-qpoll) containing a "voteholder",
:: a long list of pseudorandom numbers generated from a key.  The anon-qpoll is
:: sent to a voter, who encodes their vote as a number, adds it to a random index
:: in the voteholder, and adds a pseudorandom number generated from a key to
:: each element in the voteholder.  The anon-qpoll is then sent to another voter.
:: This procedure is repeated for all voters, and the anon-qpoll is sent back to
:: the pollmaker.  Voters send keys to the pollmaker, who can use them to
:: generate all pseudorandom number lists and subtract them out from each
:: element in the voteholder.  Any index containing a nonzero number then
:: represents a qvote.  The pollmaker then converts these numbers to qvotes,
:: checks if these qvotes are valid (not overspent and only poll options have
:: been voted for), and tallies the votes.
::
:-  %say
|=  [[now=@da eny=@uv bec=beak] ~ ~]
:-  %noun
=<
::
=/  polltitle=tape  "What color should my sigil be?"
=/  colorpoll=qpoll  :~  [%red "A fiery red"]
                         [%blue "A calming blue"]
                         [%green "A verdant green"]
                         [%purple "A royal purple"]
                         [%orange "An autumnal orange"]
                     ==
::
:: Pollmaker makes a new anonymous quadratic poll using "colorpoll", saves
:: the pollkey, and sends "newpoll" to a voter
=/  new-poll-with-key  (start-anon-qpoll colorpoll)
=/  newpoll  anon-qpoll:new-poll-with-key
=/  pollkey  key:new-poll-with-key
::
:: Voter 1 accepts "newpoll", casts a vote, saves "key1", and sends
:: "newpoll-1-vote" to the next voter
=/  vote1=qvote  ~[[%red 0] [%blue 1] [%green 4] [%purple 9] [%orange 0]]
=/  castvote1  (cast-anon-qvote [newpoll vote1])
=/  newpoll-1-vote  anon-qpoll:castvote1
=/  key1  key:castvote1
::
:: Voter 2 accepts "newpoll-1-vote", casts a vote, saves "key2", and sends
:: "newpoll-2-votes" to the next voter
=/  vote2=qvote  ~[[%red 4] [%blue 1] [%green 2] [%purple 3] [%orange 8]]
=/  castvote2  (cast-anon-qvote [newpoll-1-vote vote2])
=/  newpoll-2-votes  anon-qpoll:castvote2
=/  key2  key:castvote2
::
:: Voter 3 accepts "newpoll-2-votes", casts a vote, saves "key3", and sends
:: "newpoll-3-votes" to the pollmaker
=/  vote3=qvote  ~[[%red 5] [%blue 5] [%green 5] [%purple 0] [%orange 5]]
=/  castvote3  (cast-anon-qvote [newpoll-2-votes vote3])
=/  newpoll-3-votes  anon-qpoll:castvote3
=/  key3  key:castvote3
::
:: voters send keys to the pollmaker
=/  voterkeys=(list key)  ~[key1 key2 key3]
::
:: pollmaker tallies the poll results
:-  polltitle
(tally-anon-qpoll newpoll-3-votes pollkey voterkeys)
::
|%
::
:: an "option" is one of the choices available in a poll
+$  option  @tas
::
:: a "description" describes an option in a poll
+$  description  tape
::
:: "votes" is the number of votes for an option in a quadratic vote made by
:: an individual
+$  votes  @ud
::
:: "vote-total" is the total number of votes for an option in a poll result
+$  vote-total  @ud
::
:: "qpoll-slice" is an element of a qpoll consisting of an option and
:: a description
+$  qpoll-slice  [=option =description]
::
:: a "qpoll" is a list of options with descriptions of each option"
+$  qpoll  (list qpoll-slice)
::
:: "qvote-slice" is an element of a qvote consisting of an option and the
:: number of votes cast for that option
+$  qvote-slice  [=option =votes]
::
:: a "qvote" is a vote made by an individual containing a list of voting options
:: and the number of votes cast for each option
+$  qvote  (list qvote-slice)
::
:: a "qresult" is the result of a poll and consists of a list of options and the
:: total number of votes cast for each option
+$  qresult  (list [option vote-total])
::
:: A "voteholder" is a large list of pseudorandum numbers generated by a
:: pollmaker using a key that serves as a seed.  It is modified by voters
:: to encode votes that are inaccessable to everyone except the pollmaker.
+$  voteholder  (list @)
::
:: A "signature" is something a voter adds to an anon-qpoll to indicate that
:: they have voted.  This should probably be something like a digital signature,
:: here it's just an @p
+$  signature  @p
::
:: "insurance" is a hash of a signature, a qvote, the state of an anon-qpoll,
:: and some key (here it's just entropy).  Each voter adds insurance
:: to the qpoll and the pollmaker publishes it with the results.  If the voters
:: suspect the pollmaker has manipulated the results they could agree to share
:: their keys and vote data and verify the hashes, revealing their vote,
:: calculate the results from those votes, and compare to what the pollmaker
:: has published.
+$  insurance  @uv
+$  ballotbox
  $:  insurance=(list insurance)
      signatures=(list signature)
      =voteholder
  ==
+$  anon-qpoll  [=qpoll ballotbox]
+$  key  @
+$  anon-qpoll-and-key  [=anon-qpoll =key]
::
:: "get-options" gets the option tags from a qpoll or qvote as a list
++  get-options
  |=  =qpoll
  ^-  (list option)
  %+  turn  qpoll
  |=  b=qpoll-slice  option:b
::
:: "overspent" returns & if the total vote credits spent by a qvote is over 100,
::  else |.  For quadratic voting, the cost in vote credits is the square of
:: the number of votes made for an option summed over all options.  The number
:: of alloted voting credits could be set to any number here.  If set to "1",
:: the poll becomes a "normal" (non-quadratic) poll.
++  overspent
  |=  =qvote
  ^-  ?
  =|  total-used-credits=@ud
  =|  index=@ud
  |-
  ?:  (lth index (lent qvote))
  %=  $
  ::
  :: Square the number of votes for an option and add that
  :: value to "total-used-credits"
  total-used-credits   %+  add  total-used-credits
                       (pow votes:(snag index qvote) 2)
  ::
  index                +(index)
  ==
  ?:  (gth total-used-credits 100)
  &
  |
::
:: "nonoption" returns & if a qvote contains options not in a qpoll, else |
++  nonoption
  |=  [=qpoll =qvote]
  =/  options=(list option)  (get-options qpoll)
  =|  index=@ud
  |-
  ^-  ?
  ?.  (lth index (lent qvote))
  |
  ?.
  :: expression below is false if the @tas at index in the qvote
  :: isn't in the options list
  %+  lien  options
  |=(b=option =(b option:(snag index qvote)))
  &
  $(index +(index))
::
:: "cast-qvote" prepares a vote for casting, making sure vote credits aren't
::  overspent and votes are only for options in the poll
++  cast-qvote
  |=  [=qpoll a=qvote]
  ^-  qvote
  ?:  (overspent a)
  ~|("vote credits are overspent" !!)
  ?:  (nonoption qpoll a)
  ~|("the vote contains options not available in the poll" !!)
  a
::
:: "sum-qvotes" sums the votes for each option in "qpoll" from a list of
:: qvotes "a" and returns a qresult
++  sum-qvotes
  |=  [=qpoll a=(list qvote)]
  ^-  qresult
  =/  options=(list option)  (get-options qpoll)
  =|  index-options=@ud
  =|  votesum=@ud
  =/  allvotes=(list qvote-slice)  (zing a)
  =|  index-allvotes=@ud
  =|  result=qresult
  |-
  ::
  ::  Iterate  over all options:
  ?:  (lth index-options (lent options))
  ::
  :: Iterate over all votes:
  ?:  (lth index-allvotes (lent allvotes))
  ::
  ::  If the current option matches the option in a vote:
  ?:  .=  (snag index-options options)
      option:(snag index-allvotes allvotes)
  ::
  :: Increase votesum by the vote amount
  %=  $
  votesum          %+  add  votesum
                   votes:(snag index-allvotes allvotes)
  ::
  index-allvotes   +(index-allvotes)
  ==
  %=  $
  index-allvotes   +(index-allvotes)
  ==
  ::
  :: Add a cell containing the current option and the votesum for that option
  :: from all votes to the qresult "result"
  %=  $
  result          :_  result
                  :-  (snag index-options options)
                  votesum
  ::
  votesum         0
  index-allvotes  0
  index-options   +(index-options)
  ==
  (flop result)
::
:: "tally" checks if a list of qvotes is valid (voting credits are not overspent
:: and only options in the qpoll have been voted for), then sums the qvotes and
:: returns a qresult
++  tally
  |=  [=qpoll a=(list qvote)]
  =|  index-a=@ud
  |-
  ^-  qresult
  ::
  :: make sure all votes are valid (not overspent and only
  :: available options have been voted for):
  ?:  (lth index-a (lent a))
  ?:  (overspent `qvote`(snag index-a `(list qvote)`a))
  ~|("a vote is overspent" !!)
  ?:  (nonoption qpoll `qvote`(snag index-a `(list qvote)`a))
  ~|("an option not available in the poll is present in a vote" !!)
  $(index-a +(index-a))
  (sum-qvotes qpoll a)
::
:: "start-anon-qpoll" initializes an anonymous qpoll by generating a voteholder,
:: and returns an anon-qpoll to be sent to a voter and a poll key that is kept
:: by the pollmaker
++  start-anon-qpoll
  |=  =qpoll
  ^-  anon-qpoll-and-key
  =/  =key  eny
  =/  randomnumber=@  (shaz key)
  =|  =voteholder
  =|  count=@
  |-
  ::
  :: "10.000" in the line below defines the size of the "voteholder".  Bigger
  :: is better (less chance of 2 votes randomly being put in the same slot) but
  :: increases the time needed for the program to run.
  ?:  (lth count 10.000)
  %=  $
  voteholder     [randomnumber voteholder]
  randomnumber   (shaz (add key randomnumber))
  count          +(count)
  ==
  [[qpoll [~ ~ (flop voteholder)]] key]
::
:: "cast-anon-qvote" adds a qvote to an anon-qpoll by encoding the qvote
:: in a random slot in the voteholder and returns the updated anon-qpoll,
:: which should be sent to another voter, and a key to be sent to the pollmaker.
++  cast-anon-qvote
  |=  [a=anon-qpoll =qvote]
  ^-  anon-qpoll-and-key
  ::
  =/  mysignature=@p  p.bec
  =/  myinsurance=@  %-  shad
  (add eny (add mysignature (add (sham a) (sham qvote))))
  =|  new-voteholder=voteholder
  ::
  :: Confirm that 'q' is a valid qvote for the poll (voting credits not
  :: overspent and votes only made for options in the poll)
  ?:  (overspent qvote)
  ~|("vote credits are overspent" !!)
  ?:  (nonoption qpoll:a qvote)
  ~|("the vote contains options not available in the poll" !!)
  ::
  ::  encode the qvote 'q' as an atom using the jam function
  =/  qvote-atom=@  (jam qvote)
  ::
  ::  generate a random number used for both generating a random voteholder
  ::  index where the qvote-atom is inserted and generating a "keyforpollmaker"
  =/  random=@  (shaz (add eny +((lent signatures:a))))
  =/  randomindex=@  (mod random (lent voteholder:a))
  =/  keyforpollmaker=key  (shaz random)
  =/  random-addend=@  (shaz keyforpollmaker)
  =|  index-voteholder=@
  =/  length-voteholder=@  (lent voteholder:a)
  |-
  ::
  :: Iterate through all elements of voteholder
  ?:  (lth index-voteholder length-voteholder)
  ::
  :: If the current index is equivalent to "randomindex":
  ?:  =(index-voteholder randomindex)
  ::
  :: Add "random-addend" AND qvote-atom to the value of the element at
  :: index-voteholder, calculate the next random-addend, and increment
  ::index-voteholder
  %=  $
  new-voteholder     :_  new-voteholder
                     %+  add  (snag index-voteholder voteholder:a)
                     (add qvote-atom random-addend)
  ::
  random-addend      (shaz (add keyforpollmaker random-addend))
  index-voteholder   +(index-voteholder)
  ==
  ::
  :: If the current index is NOT equivalent to "randomindex",
  :: Add "random-addend" to the value of the element at index-voteholder,
  :: calculate the next random-addend, and increment index-voteholder
  %=  $
  new-voteholder      :_  new-voteholder
                      %+  add  (snag index-voteholder voteholder:a)
                      random-addend
  ::
  random-addend       (shaz (add keyforpollmaker random-addend))
  index-voteholder    +(index-voteholder)
  ==
  ::
  :: Add signature and insurance to the qpoll, update voteholder, and return
  :: the anon-qpoll and the key used to generate the random addends. If
  :: "signatures" is not empty, insert mysignature at a random index in the
  :: "signatures" list
  :_  keyforpollmaker
  :-  qpoll:a
  :-  [myinsurance insurance:a]
  ?~  [signatures:a]
  :-  [mysignature signatures:a]
  (flop new-voteholder)
  =/  randomindex2=@  (mod (add eny (sham insurance)) (lent signatures:a))
  :-  (into signatures:a randomindex2 mysignature)
  (flop new-voteholder)
::
:: "atomtoqvote" converts an atom into a qvote using the "cue" funtion and
:: type information from a sample vote
++  atomtoqvote
  |=  [=anon-qpoll qvote-atom=@]
  ^-  qvote
  ::
  :: generate a sample qvote for an anon-qpoll
  =/  sample-qvote=qvote
  %+  turn  qpoll:anon-qpoll
  |=  =qpoll-slice  [option:qpoll-slice 0]
  ::
  :: generate a vase using sample-vote
  =/  b  !>  sample-qvote
  :: replace the noun in the vase b with the noun generated by using the cue
  :: function on "qvote-atom", then generate a qvote from the vase
  =.  q.b  (cue qvote-atom)
  !<  qvote  b
::
:: "subtract-voteholder" subtracts a unique value generated from a "key" from
:: every element in a voteholder.  It is used to subtract the values added to
:: the voteholder when "cast-anon-qvote" or "start-anon-qpoll" has been used.
++  subtract-voteholder
  |=  [v=voteholder =key]
  ^-  voteholder
  =|  index=@
  =/  subtrahend=@  (shaz key)
  =/  length-v  (lent v)
  =|  new-voteholder=voteholder
  |-
  ?:  (lth index length-v)
  %=  $
  new-voteholder  :_  new-voteholder
                  (sub (snag index v) subtrahend)
  ::
  subtrahend      (shaz (add key subtrahend))
  index           +(index)
  ==
  (flop new-voteholder)
::
:: "tally anon-qpoll" accepts an anon-qpoll ready to be tallied, the pollmaker
:: key, and the voter keys.  It subtracts all the key-generated values added to
:: the voteholder, so that any element in the voteholder that is not zero
:: represents a qvote added by the "cast-anon-qvote" function.  The numbers
:: are the converted to qvotes using the "atomtoqvote" function, and votes
:: are tallied.
++  tally-anon-qpoll
  |=  [a=anon-qpoll mykey=key voterkeys=(list key)]
  =/  allkeys=(list key)  [mykey voterkeys]
  =|  all-keys-index=@
  =/  length-all-keys  (lent allkeys)
  |-
  ::
  :: Iterate through all keys, subtracting the key-dependent value from each
  :: element in voteholder for each key
  ?:  (lth all-keys-index length-all-keys)
  %=  $
  voteholder.a      %+  subtract-voteholder  voteholder.a
                    (snag all-keys-index allkeys)
  ::
  all-keys-index    +(all-keys-index)
  ==
  ::
  :: make a list of all nonzero elements after all key-dependent values have
  :: been subtracted out
  =/  qvote-atoms=(list @)
  %+  skip  `voteholder`voteholder.a
  |=(a=@ =(a 0))
  ::
  :: There is some chance that 2 or more votes could randomly get inserted
  :: into the same index in the voteholder.  To test if that may have happened,
  :: compare the number of signatures with the number of qvote-atoms.  If these
  :: values dont match give an error message.
  ?.  =((lent qvote-atoms) (lent signatures:a))
  ~|("number of votes doesn't match number of signatures- could be 2 votes in same voteholder position" !!)
  ::
  :: convert qvote-atoms to qvotes
  =/  qvotes=(list qvote)
  %+  turn  qvote-atoms
  |=  b=@  (atomtoqvote a b)
  ::
  =/  voteresult=qresult  (tally qpoll:a qvotes)
  ::
  :^  `(list [option description])`qpoll:a
      insurance:a
      signatures:a
      voteresult
--
