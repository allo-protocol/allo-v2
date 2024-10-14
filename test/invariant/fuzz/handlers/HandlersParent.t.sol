// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {HandlerAllo} from "./HandlerAllo.t.sol";
import {HandlerAnchor} from "./HandlerAnchor.t.sol";
import {HandlerRegistry} from "./HandlerRegistry.t.sol";

contract HandlersParent is HandlerAllo, HandlerAnchor, HandlerRegistry {}
