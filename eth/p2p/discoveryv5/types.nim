import
  std/hashes,
  stint,
  eth/rlp, enr, node

{.push raises: [Defect].}

const
  aesKeySize* = 128 div 8

type
  AesKey* = array[aesKeySize, byte]

  HandshakeKey* = object
    nodeId*: NodeId
    address*: string # TODO: Replace with Address, need hash

  MessageKind* = enum
    # TODO This is needed only to make Nim 1.2.6 happy
    #      Without it, the `MessageKind` type cannot be used as
    #      a discriminator in case objects.
    unused = 0x00

    ping = 0x01
    pong = 0x02
    findnode = 0x03
    nodes = 0x04
    talkreq = 0x05
    talkresp = 0x06
    regtopic = 0x07
    ticket = 0x08
    regconfirmation = 0x09
    topicquery = 0x0A

  RequestId* = object
    id*: seq[byte]

  PingMessage* = object
    enrSeq*: uint64

  PongMessage* = object
    enrSeq*: uint64
    ip*: seq[byte]
    port*: uint16

  FindNodeMessage* = object
    distances*: seq[uint32]

  NodesMessage* = object
    total*: uint32
    enrs*: seq[Record]

  TalkReqMessage* = object
    protocol*: seq[byte]
    request*: seq[byte]

  TalkRespMessage* = object
    response*: seq[byte]

  # Not implemented, specification is not final here.
  RegTopicMessage* = object
  TicketMessage* = object
  RegConfirmationMessage* = object
  TopicQueryMessage* = object

  SomeMessage* = PingMessage or PongMessage or FindNodeMessage or NodesMessage or
    TalkReqMessage or TalkRespMessage

  Message* = object
    reqId*: RequestId
    case kind*: MessageKind
    of ping:
      ping*: PingMessage
    of pong:
      pong*: PongMessage
    of findnode:
      findNode*: FindNodeMessage
    of nodes:
      nodes*: NodesMessage
    of talkreq:
      talkreq*: TalkReqMessage
    of talkresp:
      talkresp*: TalkRespMessage
    of regtopic:
      regtopic*: RegTopicMessage
    of ticket:
      ticket*: TicketMessage
    of regconfirmation:
      regconfirmation*: RegConfirmationMessage
    of topicquery:
      topicquery*: TopicQueryMessage
    else:
      discard

template messageKind*(T: typedesc[SomeMessage]): MessageKind =
  when T is PingMessage: ping
  elif T is PongMessage: pong
  elif T is FindNodeMessage: findNode
  elif T is NodesMessage: nodes
  elif T is TalkReqMessage: talkreq
  elif T is TalkRespMessage: talkresp

proc read*(rlp: var Rlp, T: type RequestId): T
    {.raises: [ValueError, RlpError, Defect].} =
  mixin read
  var reqId: RequestId
  reqId.id = rlp.toBytes()
  if reqId.id.len > 8:
    raise newException(ValueError, "RequestId is > 8 bytes")
  rlp.skipElem()

  reqId

proc append*(writer: var RlpWriter, value: RequestId) =
  writer.append(value.id)

proc hash*(reqId: RequestId): Hash =
  hash(reqId.id)

proc toBytes*(id: NodeId): array[32, byte] {.inline.} =
  id.toByteArrayBE()

proc hash*(id: NodeId): Hash {.inline.} =
  result = hashData(unsafeAddr id, sizeof(id))

# TODO: To make this work I think we also need to implement `==` due to case
# fields in object
proc hash*(address: Address): Hash {.inline.} =
  hashData(unsafeAddr address, sizeof(address))

proc hash*(key: HandshakeKey): Hash =
  result = key.nodeId.hash !& key.address.hash
  result = !$result
