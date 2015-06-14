<a name="v0.7.1"></a>
# v0.7.1 (2015-06-14)

## Bug Fixes

- Fix infinite recursion when parsing a color ([0c4ed7c6](https://github.com/abe33/atom-pigments/commit/0c4ed7c6e8c1e2a6d391c6ec08a7117372de5a0a), [#19](https://github.com/abe33/atom-pigments/issues/19))
- Fix typo in method name ([8e5c9423](https://github.com/abe33/atom-pigments/commit/8e5c9423124f994b37f7d0d1cf634cdc98fa710f))

<a name="v0.7.0"></a>
# v0.7.0 (2015-06-14)

## Features

- Add convert to hex and convert to rgba commands ([592157b3](https://github.com/abe33/atom-pigments/commit/592157b31bf1e6fe813071745b09e68bf1922c4e), [#22](https://github.com/abe33/atom-pigments/issues/22))
  <br>Available in the context when over a color.
- Add method on color buffer to retrieve color markers with buffer position ([ba00c5d8](https://github.com/abe33/atom-pigments/commit/ba00c5d894dfd88dfae9dba02c686fdfa7d5669f))
- Add method on color markers to convert its content to hex or rgba ([3ef5a337](https://github.com/abe33/atom-pigments/commit/3ef5a3374b555e1ed1ef47b9b15692c88676e4fc))
- Add support for sass complement function ([75e03377](https://github.com/abe33/atom-pigments/commit/75e03377639d0896c470bfe11a9b484180eb4632))
- Add support for stylus blend function ([c601c647](https://github.com/abe33/atom-pigments/commit/c601c647213f5cce0d6deae5809a284bc0e08390))
- Add support for less blending functions ([30fbe00e](https://github.com/abe33/atom-pigments/commit/30fbe00ef207923fbcd2390a15ecbb057e731f0c))
- Add support for less contrast function ([ffb6904b](https://github.com/abe33/atom-pigments/commit/ffb6904bd05b3a0f89975b79a0f93e6740f139da))
- Add support for less fade function ([5470dabb](https://github.com/abe33/atom-pigments/commit/5470dabba1d6570cce79a0e385ce15cbfbb59a29))
- Add support for less spin function ([e47ed885](https://github.com/abe33/atom-pigments/commit/e47ed8856838a94a2ee4acc6575519710abc0016))

## Bug Fixes

- Fix mix operation not working with color expression with paranthesis ([4bef6832](https://github.com/abe33/atom-pigments/commit/4bef6832d53b74b7d6e171404320fa57d7e304a1))

<a name="v0.6.0"></a>
# v0.6.0 (2015-06-11)

## Features

- Add a square dots marker renderer ([4b73948b](https://github.com/abe33/atom-pigments/commit/4b73948b4ef8172488de72dc017ddd21f4140ad1), [#15](https://github.com/abe33/atom-pigments/issues/15))

## Bug Fixes

- Remove annoying warning dialog for large project ([30cd2553](https://github.com/abe33/atom-pigments/commit/30cd2553677b2aeaa605a5e84251eea47975c7d9), [#23](https://github.com/abe33/atom-pigments/issues/23))

<a name="v0.5.0"></a>
# v0.5.0 (2015-06-11)

## Features

- Implement a variable that allow to speed up considerably considerably. ([c7ffc5c1](https://github.com/abe33/atom-pigments/commit/c7ffc5c19bf280928d204ea3b6ae5dfe5a931907))
- Bump markers version ([e483bb34](https://github.com/abe33/atom-pigments/commit/e483bb340683942eefc4d363b6512e1a50083cf2))

## Bug Fixes

- Fix outline, underline and dot markers hidden by tiles ([818930fc](https://github.com/abe33/atom-pigments/commit/818930fca4b6c4a1e9e1879499fe656b4ed4ba6d), [#26](https://github.com/abe33/atom-pigments/issues/26))
- Fix issue with variables update when rescanning a buffer ([5080531a](https://github.com/abe33/atom-pigments/commit/5080531a83ff6d578dd8210eea9ae5f419099d40))

## Performances

- Remove variables markers created in text buffer ([f701b6b9](https://github.com/abe33/atom-pigments/commit/f701b6b9ce01174154e90755c233afc2264b8eab))

<a name="v0.4.5"></a>
# v0.4.5 (2015-06-05)

## Bug Fixes

- Fix error raised when filtering the variables if there's no variables ([70e546c8](https://github.com/abe33/atom-pigments/commit/70e546c81dda1f181693291173c306fe8cf6d44b))
- Fix glob pattern matching not consistent between project and loader ([503d274c](https://github.com/abe33/atom-pigments/commit/503d274ca8054488fdea36ca35c539c2c2fb9890))

<a name="v0.4.4"></a>
# v0.4.4 (2015-06-03)

## Bug Fixes

- Fix markers horizontal scroll not in sync with editor tiles ([264450b5](https://github.com/abe33/atom-pigments/commit/264450b591c59481010ce927c643ad8ab3689c84))

<a name="v0.4.3"></a>
# v0.4.3 (2015-06-03)

## Bug Fixes

- Fix scroll still not in sync if there's no tiles when setting the model ([5d4b93a4](https://github.com/abe33/atom-pigments/commit/5d4b93a4a3a4a37317f0acf483195f99b3955dac), [#25](https://github.com/abe33/atom-pigments/issues/25))

<a name="v0.4.2"></a>
# v0.4.2 (2015-06-03)

## Bug Fixes

- Fix color markers not synced with editor scroll ([dded923d](https://github.com/abe33/atom-pigments/commit/dded923d103592fa2b4cf17d0d1f34ed22b90732), [#25](https://github.com/abe33/atom-pigments/issues/25))

<a name="v0.4.1"></a>
# v0.4.1 (2015-06-02)

## Features

- Add `vendor/*`, `spec/*` and `test/*` as default ignored names. ([96381ecf](https://github.com/abe33/atom-pigments/commit/96381ecf1c643300aa091c744149e28207e0c0bc))

## Bug Fixes

- Raise the threshold to avoid annoying user ([15b05c07](https://github.com/abe33/atom-pigments/commit/15b05c07885aaac2062c5c2b5aa40f892795bc9a))
- Fix paths and variables not updated when the paths settings are changed ([8e259a8a](https://github.com/abe33/atom-pigments/commit/8e259a8a81f0aed8744ab381d6a44c6f3609f85c))

<a name="v0.4.0"></a>
# v0.4.0 (2015-06-01)

## Features

- Add border radius to background markers ([3a9efc6a](https://github.com/abe33/atom-pigments/commit/3a9efc6ab12132820ece1bd2509834f81abb839d))
- Add a second version property in serialized data ([53fb3c1c](https://github.com/abe33/atom-pigments/commit/53fb3c1c91a0806e2f3305792caf4f82f6ee1df4))  <br>This version will only be used for markers data (variables and buffers
  data). So that we can drop these data without affecting the project
  specific data.
- Implement an alert on large project loading to ignores the paths ([05ba87f4](https://github.com/abe33/atom-pigments/commit/05ba87f45ef622d5811f11672d1314e125d8229f))

## Bug Fixes

- Fix variables defined after a mixin not found by scanner ([8f000e59](https://github.com/abe33/atom-pigments/commit/8f000e59a0c7aeea74a8a1475d7d543b98568c59))
- Fix variables and colors not handled for file not in project ([4bb84b72](https://github.com/abe33/atom-pigments/commit/4bb84b72d8e6a795335df462f804f91760a66da4))
- Prevent call stack errors when building the variables regexp ([3aa322cb](https://github.com/abe33/atom-pigments/commit/3aa322cb033aafbd5a4e6c84804342751ca21205))
- Fix broken anchor tag. ([f0ff40a7](https://github.com/abe33/atom-pigments/commit/f0ff40a7bbad999763cf0dcd0b0ed8f3766517b0))
- Fix error raised when an invalid regexp is set in ignored scopes ([d4527c68](https://github.com/abe33/atom-pigments/commit/d4527c6843766584541c25a1f610e21e26d11340), [#14](https://github.com/abe33/atom-pigments/issues/14))

<a name="v0.3.1"></a>
# v0.3.1 (2015-05-19)

## Bug Fixes

- Add alpha rounding after 3 decimals in palette view ([69638149](https://github.com/abe33/atom-pigments/commit/696381498dd4951aebc57fd3f6c0368e139bd59a))
- Fix accessing variables with id or name when there's no variables yet ([8155b945](https://github.com/abe33/atom-pigments/commit/8155b945f81fe834aabc99a74369670b241da96b), [#17](https://github.com/abe33/atom-pigments/issues/17))

<a name="v0.3.0"></a>
# v0.3.0 (2015-05-18)

## Features

- Add relative units for dot markers and autocomplete preview ([d3350386](https://github.com/abe33/atom-pigments/commit/d335038679f3338c3b9a26b846383b6dec988d83), [#11](https://github.com/abe33/atom-pigments/issues/11))
- Add a pigments:reload command to reload project variables ([1b3f51d6](https://github.com/abe33/atom-pigments/commit/1b3f51d6898cf2a551591bfe9e49b3d49a10978b))
  <br>As proposed in #7.
- Add node_modules as default ignored name ([e4ab734a](https://github.com/abe33/atom-pigments/commit/e4ab734ad22a0589b7d8a79ae96c650451ed1104))
  <br>As proposed in #7
- Implement rendering colors from variables only for variables sources ([fcb15da9](https://github.com/abe33/atom-pigments/commit/fcb15da97af37b2b6269aa780862ec8f22a4946d))

## Bug Fixes

- Fix attributes selectors being parsed as variables ([d7407e4c](https://github.com/abe33/atom-pigments/commit/d7407e4c291d42c80791ac17c11dce00f14ba618))

<a name="v0.2.1"></a>
# v0.2.1 (2015-05-14)

## Bug Fixes

- Fix mixins/functions arguments being parsed as variables ([e7a6fc17](https://github.com/abe33/atom-pigments/commit/e7a6fc178aa962c313ba7c3ce68301036526f093))

<a name="v0.2.0"></a>
# v0.2.0 (2015-04-30)

## Features

- Implement a delay before scanning the buffer after an input ([1ba5ee49](https://github.com/abe33/atom-pigments/commit/1ba5ee4956d81f00c5f086f0738fc2da27d89245))

## Bug Fixes

- Fix tasks still running when starting typing again ([fb185a2d](https://github.com/abe33/atom-pigments/commit/fb185a2d464212a23402d5258845af3141103a39))
- Fix provider not providing variable prefixed with $ ([f1752225](https://github.com/abe33/atom-pigments/commit/f1752225f729d84c854c728392528a3c62390134))

<a name="v0.1.4"></a>
# v0.1.4 (2015-04-24)

## Bug Fixes

- Fix invalid colors displayed in search results ([1534ea49](https://github.com/abe33/atom-pigments/commit/1534ea490ad3ccd20949f7aef7b73f5b4076a11d), [#3](https://github.com/abe33/atom-pigments/issues/3))

<a name="v0.1.3"></a>
# v0.1.3 (2015-04-23)

## Bug Fixes

- Implement strict matching in autocomplete provider ([028c3a9f](https://github.com/abe33/atom-pigments/commit/028c3a9f441d414bb3145d61a892e933920a4c61), [#3](https://github.com/abe33/atom-pigments/issues/3))
- Fix context returning invalid colors ([dc47cd1d](https://github.com/abe33/atom-pigments/commit/dc47cd1df920457215bfd2de5299c8c462a3b17a), [#4](https://github.com/abe33/atom-pigments/issues/4))

<a name="v0.1.2"></a>
# v0.1.2 (2015-04-22)

## Features

- Add json version in serialized data ([b432a50a](https://github.com/abe33/atom-pigments/commit/b432a50a82ae31ae9f6e44d532ddb3a2a0c1870b))

## Bug Fixes

- Fix invalid colors not detected by parser ([33674063](https://github.com/abe33/atom-pigments/commit/336740635241dea118972b5f914e572591fcf4bc), [#2](https://github.com/abe33/atom-pigments/issues/2))
- Fix typo in setting's name ([f9bcbd44](https://github.com/abe33/atom-pigments/commit/f9bcbd445845e1b88d346bc89c9e04f1cf0dd6a8), [#1](https://github.com/abe33/atom-pigments/issues/1))

<a name="v0.1.1"></a>
# v0.1.1 (2015-04-22)

## Bug Fixes

- Fix markers not updated after tokenization and editor styling ([ebe5a07a](https://github.com/abe33/atom-pigments/commit/ebe5a07a56a027863351dcf7422b2f45c3aa398b))
