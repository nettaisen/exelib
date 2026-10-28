--!strict
-- What a controller brought is done (`sub_80BADE4` and the like write 0 through the pointer they were given): the
-- controller's kind's `navi_left` (a navi chip's controller, @exelib/navi_chips/controller's; EXE5's DethPhnx, which
-- brings the last navi chip's navi again).
return function(controller: Object)
    local kind = controller.kind
    local left = kind.navi_left
    if left == nil then
        error(`what a controller brought left, but the controller is a {kind.id}, which has no navi_left`)
    end
    left(controller)
end
