include("InstanceManager");

local TimerIM = InstanceManager:new("TimerTool", "TimerCon", Controls.TimeStack);
--TimerIM:ResetInstances();

CallbackDict = {};
CallbackSpeed = {};
AuxiliaryTiming = {};
ATnum = 0;

-- callbackFunc被延迟/循环的函数
-- loop是则为循环函数，不是或为nil则函数为延迟函数
-- speed是计时器速度，如果为nil则默认速度为1秒运行函数1次，既speed=0.5
-- FuncID用于额外的Remove停止循环/延时函数，记得不要为大于0的整数，给予其他字符串
-- StopTime结束时刻，当为延迟函数时，第StopTime次时结束并运行callbackFunc函数，当是循环函数该参数无效
-- 也就是你完全可以通过调控speed和StopTime来确定速度
function AddTimer(callbackFunc, loop, speed, FuncID, StopTime)
    ATnum = ATnum + 1;
    -- 如果loop为nil
    loop = loop or false;
    local num = tonumber(FuncID);
    -- 如果FuncID为数值字符串且大于0是整数
    if num and num > 0 and math.floor(num) == num then
        print("FuncID应当不为大于0的整数，应当给予其他字符串");
        print("FuncID改为"..ATnum);
        FuncID = ATnum;
    end
    -- 如果FuncID发生重复
    if AuxiliaryTiming[FuncID] ~= nil then
        print("警告FuncID: "..FuncID .."发生重复，如果需要RemoveTimer请更改FuncID，不需要则FuncID应该为空");
        print("FuncID改为"..ATnum);
        FuncID = ATnum;
    end
    -- 如果FuncID为nil
    FuncID = FuncID or ATnum;
    print("FuncID为：" ..FuncID) 
    
    local TIM = TimerIM:GetInstance(); --为了实现架构化，采用实例批量生产动画控件
    local TAnim = TIM.TimerAnim;
    speed = speed or 0.5;
    -- 设置动画控件速度公式：Speed="a" 则一秒动画2 * a次
    TAnim:SetSpeed(speed);
    
    
    
    AuxiliaryTiming[FuncID] = 0;
    
    local function play() -- 动画控件播放动画
        TAnim:SetToBeginning()
        TAnim:Play()
    end
    local function stop() -- 动画控件停止动画
        TAnim:SetToBeginning()
        TAnim:Stop()
        TimerIM:ReleaseInstance(TIM)--删除该实例
        AuxiliaryTiming[FuncID] = nil--同步清除
    end
    
    -- callbackFunc插入到定时循环中
    local function CreateLoopFunc()
        return function()
            callbackFunc();-- 运行需要循环的函数 
            play() -- 接着循环
        end
    end

    -- callbackFunc插入到延时触发中
    local function CreateFunc()
        return function()
            AuxiliaryTiming[FuncID] = AuxiliaryTiming[FuncID] + 1;
            if AuxiliaryTiming[FuncID] == StopTime then --达到要触发的时候
                callbackFunc();
                CallbackDict[FuncID] = nil;
                stop()-- 结束
                return
            end
            play() -- 接着循环
        end
    end

    local func = loop and CreateLoopFunc() or CreateFunc();
    TAnim:RegisterEndCallback( func ) --在动画结束注册回调函数
    play()
    
    -- 直接构造好对应的关闭循环的函数，亦或者提前关闭延迟的函数以免找不到对应func
    CallbackDict[FuncID] = function()
        stop()
        CallbackDict[FuncID] = nil;
        CallbackSpeed[FuncID] = nil;
    end
    CallbackSpeed[FuncID] = function(iSpeed)
        TAnim:SetToBeginning()
        TAnim:Stop()            --暂停
        TAnim:SetSpeed(iSpeed); --修改速度
        play()                  --重新启动控件
    end
    return ATnum;
end
-- 这里主要还是关闭循环的函数，亦或者提前关闭延迟的函数。
function RemoveTimer(FuncID)
    if CallbackDict[FuncID] then
       CallbackDict[FuncID](); 
    end
end
-- 调整函数循环速度
function AdjustSpeed(FuncID, iSpeed)
    if CallbackSpeed[FuncID] then
       CallbackSpeed[FuncID](iSpeed); 
    end
end

------------------------------------------------
-- 下面就是测试
-- 直接借用文明6游戏内百科按钮测试效果
-- 注意该测试结果需要可实时加载lua.log,我是使用官方SDK的FireTuner实时查看lua.log
--Events.LoadGameViewStateDone.Add(function()
    local TargetControl = ContextPtr:LookUpControl("/InGame/TopPanel/RightContents/CivpediaButton");
    local time, next = 0, 0;
    TargetControl:RegisterCallback( Mouse.eMClick, function() 
        
        AddTimer(function() time = time + 1; print("报时第: ",time) end, true, 0.5, "A"); -- 循环函数A 用于报时间
        AddTimer(function() next = next + 1; print("第几次: ",next) end, true, 0.5, "B"); -- 循环函数B 用于测试该速度
        AddTimer(function() print("10秒B变速"); AdjustSpeed("B", 1); end, false, 0.5, "C", 10); -- 延时函数C，在第10秒调整函数B速度
        AddTimer(function() print("20秒都结束");
                    RemoveTimer("A");
                    RemoveTimer("B");
                    RemoveTimer("C");
                    RemoveTimer("D");
                 end, false, 0.5, "D", 20); -- 延时函数D，停止所有函数
    end);
--end)