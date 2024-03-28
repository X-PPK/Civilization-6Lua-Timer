# 文明6lua计时器
- [Githp链接](https://github.com/X-PPK/pk-civ6-LuaTimer)
- [Gitee链接](https://gitee.com/XPPK/pk-civ6-LuaTimer)
#### 介绍
在文明6实现更好的lua计时器，用于定时触发其他lua函数，这将是我的大UI框架项目的一部分
- 目前推荐两个方法，一个是通过UI动画控件实现
- 另一个是通过Events.GameCoreEventPublishComplete.Add()实现，该方法来自[“号码菌”](https://steamcommunity.com/profiles/76561198147378701)

## 项目说明
当我想要实现更加复杂的外交动画那么计时器就是必要的，因为我想控控制贴图切换的速度
这个项目旨在试图解决这个问题

这里将一点一点记录我这个项目的实现过程，如果他实现了，也就将进行公开

- xxx全搜，指用类似AgentRansack对后缀是xxx的文件全盘搜索（个人习惯）
- 不要嫌弃我这个啰嗦，一开始就是我的日记总结，第一用途就是保证日后我如果要继续这个项目研究，不会因为时间太久而忘记太多细节，最后导致只能放弃，本人容易忘细节

## 项目的开始
### 1.  2023/5/？具体时间忘记了
当我有了计时器的想法后第一时间想到了一个lua中的while循环+os.time()
    - os.time()是lua获取系统当前时间
    - 具体代码如下
    - 注意这个方法已经被弃用，可以跳过
我使用 `os.time()` 函数来获取当前时间，再根据当前时间和起始时间的差值来计算时间间隔。
#### 使用 while 循环实现计时器
```lua
function timer(seconds)
    local start_time = os.time() -- 获取当前时间
    local elapsed_time = 0

    while elapsed_time < seconds do
        -- 执行计时任务
        print("计时中...", elapsed_time, "秒")
        -- 等待一秒
        os.execute("sleep 1")

        -- 更新已经流逝的时间
        elapsed_time = get_time() - start_time
    end

    print("计时完成！")
end

-- 测试计时器
timer(10)  -- 计时 10 秒
```

在上面的代码中，我们定义了一个 `get_time()` 函数来获取当前时间，然后定义了一个 `timer()` 函数来实现计时任务。

首先，在 `timer()` 函数中获取当前时间作为计时器的起始时间，并初始化流逝的时间为零。然后，在 `while` 循环中执行计时任务，每次循环等待一秒，同时更新已经流逝的时间。当流逝的时间达到指定的计时时间时，退出循环，并输出计时完成的提示。

需要注意的是，由于 `os.execute()` 函数在不同操作系统中可能存在差异，请根据实际情况修改代码。此外，计时器的精度可能受到操作系统、硬件等多方面因素的影响，因此在实际应用中需要进行多次测试以确保结果的准确性。

## CIV6动画控件计时器
- 由于os.execute()可能不太稳定，所以我希望是否可以用CIV6lua系统支持的东西实现
- 我就想到了CIV6的一种UI控件————AlphaAnim（动画UI控件）
我在之前对官方UI研究中知道AlphaAnim有参数Speed可以控制动画控件的动画变动速度
- 同时AlphaAnim控件可以注册动画回调函数，让动画变动中插入运行函数——RegisterAnimCallback

- 所以理论上完全可行，那么就是实践了
-- 这个我已经实现了，但暂时没整理，有空整理


### 具体例子
-  2023/8/11
- 因为用到的是文明6UI的控件，所以是UI的xml和lua
- 当然一如既往的详细备注，以帮助大家理解
- 这里写了一个CIV6动画控件计时器测试mod，文件可以自己取：[计时器测试mod](https://gitee.com/XPPK/pk-civ6-LuaTimer/tree/master/计时器测试mod)

首先下面两个例子(构造计时循环和定时器)的xml相同我就放一起了
```xml
<?xml version="1.0" encoding="utf-8"?>
<Context Name="PKTimer">
	<!-- 这里具体来说是透明度变化的动画控件，其他参数不是很重要， -->
	<!-- 主要是周期Cycle=""要为Once一周期，表示动画控件被激活只运行一次 -->
	<!-- 这样就可以在lua控制控件在运行结束时启动新的周期，从而实现循环运行我们的函数达到计时 -->
	<AlphaAnim ID="TimerAnim" AlphaStart="1" AlphaEnd="1" Size="0,0"  Cycle="Once"  Speed="1"/>
</Context>
```

#### 构造计时循环
- 例如你希望这个函数每1秒运行一次
```lua
-- 官方例子Speed明确为最小值0.0015（也就是这至少可以取到小数点后4位）
-- 官方还有一些不明确数值例子是计算值我没有测试也没时间取探索，不清楚Speed具体能取到多少
--    ...省略
--    speed = 0.005 --此时动画控件1秒内完成动画播放1/100次(既100秒 运行1次函数)
--    speed = 0.01  --此时动画控件1秒内完成动画播放1/50次 (既50秒  运行1次函数)
--    speed = 0.05  --此时动画控件1秒内完成动画播放1/10次 (既10秒  运行1次函数)
--    speed = 0.1   --此时动画控件1秒内完成动画播放1/5次  (既5秒   运行1次函数)
--    speed = 0.25  --此时动画控件1秒内完成动画播放1/2次  (既2秒   运行1次函数)
local speed = 0.5   --此时动画控件1秒内完成动画播放1次    (既1秒   运行1次函数)
--    speed = 1     --此时动画控件1秒内完成动画播放2次    (既0.5秒 运行1次函数)
--    speed = 2     --此时动画控件1秒内完成动画播放4次    (既0.25秒运行1次函数)
--    speed = 30    --此时动画控件1秒内完成动画播放60次   (既1/60秒运行1次函数)
--    ...省略
--    speed = a     --此时动画控件1秒内完成动画播放2*a次  (既1/2a秒运行1次函数)
function function1()
    -- 省略你具体按speed设定速度循环要工作的代码程序
end
local function play() -- 动画控件播放动画
    Controls.TimerAnim:SetToBeginning()
    Controls.TimerAnim:Play()
end

-- 这里主要还是关闭循环的函数，亦或者提前关闭延迟的函数。
function stop() -- 动画控件停止动画
    Controls.TimerAnim:SetToBeginning()
    Controls.TimerAnim:Stop()
end
function AddTimer(func, iSpeed)
    Controls.TimerAnim:SetSpeed(iSpeed);
    Controls.TimerAnim:RegisterEndCallback(function()
        func()
        play() -- 接着循环
    end);
end
function AdjustSpeed(iSpeed) -- 调整function1这个循环函数循环速度时
    function3() 
    Controls.TimerAnim:SetSpeed(iSpeed);
    play()
end
---------------------
AddTimer(function1, speed) -- 现在function1这个循环函数每1秒运行一次
```
#### 定时器
- 例如你希望这个函数延迟10秒后运行
```lua
local speed = 0.5   --此时动画控件1秒内完成动画播放1次 (既1秒运行1次函数)
local AuxiliaryTiming = 0 -- 用于记录延迟函数运行次数
function function1()
    -- 省略你具体按speed设定速度循环要工作的代码程序
end
end
local function play() -- 动画控件播放动画
    Controls.TimerAnim:SetToBeginning()
    Controls.TimerAnim:Play()
end

-- 这里主要还是关闭循环的函数，亦或者提前关闭延迟的函数。
function stop() -- 动画控件停止动画
    Controls.TimerAnim:SetToBeginning()
    Controls.TimerAnim:Stop()
end
function AddTimer(func, iSpeed, StopTime)
    Controls.TimerAnim:SetSpeed(iSpeed);
    Controls.TimerAnim:RegisterEndCallback(function()
        func()
        if AuxiliaryTiming == StopTime then --达到要触发的时候
            stop()-- 结束
            return
        end
        play() -- 接着循环
    end);
end
function AdjustSpeed(iSpeed) -- 调整function1这个循环函数循环速度时
    function3() 
    Controls.TimerAnim:SetSpeed(iSpeed);
    play()
end

```
#### 计时器框架
##### lua部分
```lua
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
function AddTimer(callbackFunc, loop, speed, FuncID, StopTime, Values)
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
            callbackFunc(Values);-- 运行需要循环的函数 
            play() -- 接着循环
        end
    end

    -- callbackFunc插入到延时触发中
    local function CreateFunc()
        return function()
            AuxiliaryTiming[FuncID] = AuxiliaryTiming[FuncID] + 1;
            if AuxiliaryTiming[FuncID] == StopTime then --达到要触发的时候
                callbackFunc(Values);
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
-- 注意该测试结果需要可实时加载lua.log,我是使用官方SDK的FireTuner实时查看lua.log
-- 使用官方SDK的FireTuner运行LuaEvents.PK_TestCode()即可
function TestCode() 
        
    AddTimer(function() time = time + 1; print("报时第: ",time) end, true, 0.5, "A"); -- 循环函数A 用于报时间
    AddTimer(function() next = next + 1; print("第几次: ",next) end, true, 0.5, "B"); -- 循环函数B 用于测试该速度
    AddTimer(function() print("10秒B变速"); AdjustSpeed("B", 1); end, false, 0.5, "C", 10); -- 延时函数C，在第10秒调整函数B速度
    AddTimer(
        function() print("20秒都结束");
            RemoveTimer("A");
            RemoveTimer("B");
            RemoveTimer("C");
            RemoveTimer("D");
        end,
        false, 0.5, "D", 20
    ); -- 延时函数D，停止所有函数
end
LuaEvents.PK_TestCode.Add(TestCode);
------------------------------------------------
-- 补充,首先感谢号码菌的建议，我前面没有考虑到这一点，现在更新改动加入Values参数
-- 这里额外讲述一下Values的使用：
-- 1. 首先Values可以为空(nil)，但这样会给予callbackFunc一个nil参数
   -- 所以要确保你的callbackFunc要么一开始就不需要参数，要么能接受nil参数，不会导致什么BUG产生
-- 2. 然后Values是作为函数参数传递的，它可以是一个参数直接给予callbackFunc使用
-- 3. 但如果你需要给予callbackFunc多个参数，那么Values应当作为一个table，
   -- 你只需要直接这个table按顺序填入要给予callbackFunc的多个参数，然后在callbackFunc函数里有对应的处理方法
   -- 例如：
   -- function Func(Values)
   --     local a,b = Values[1],Values[2]; -- 简单的直接对应的处理方法
   --     print(a,b)
   -- end
```

##### xml部分
```xml
<?xml version="1.0" encoding="utf-8"?>
<!-- PK_CIV6_Timer -->
<!-- Author: 皮皮凯 -->
<Context Name="PKTimer">
	<Container Size="0,0" Anchor="C,C" Hidden="1">
		<Stack	ID="TimeStack" Anchor="C,C"/>
	</Container>

	<Instance Name="TimerTool">
		<Container ID="TimerCon" Size="auto,auto">
			<!-- 这里具体来说是透明度变化的动画控件，其他参数不是很重要， -->
			<!-- 主要是周期Cycle=""要为Once一周期，表示动画控件被激活只运行一次 -->
			<!-- 这样就可以在lua控制控件在运行结束时启动新的周期，从而实现循环运行我们的函数达到计时 -->
			<AlphaAnim ID="TimerAnim" AlphaStart="1" AlphaEnd="1" Size="0,0"  Cycle="Once"  Speed="1"/>
		</Container>
	</Instance>
</Context>
```
- 测试结果如下
![输入图片说明](%E8%AE%A1%E6%97%B6%E5%99%A8%E6%B5%8B%E8%AF%95mod/2image.png)
#### 小扩展
- 然后动画控件随你游戏设置帧率刷新，而这我发现动画控件还可以插入一个随着帧率刷新调用函数
- 具体细节忘记了也懒得总结，难不成你要按帧率运行函数？？,大部分玩家电脑顶不住的啊大哥，如果是为了按帧率切换图片实现播放视频，我想说没必要用这个，我有更好方法来实现，直接播放视频的UI控件

```lua
Controls.CountdownTimerAnim:RegisterAnimCallback( OnUpdateTimers );--测试这个看样子是每帧回调

Controls.CountdownTimerAnim:ClearAnimCallback();--对应的结束运行
```

## Events计时器
- 2024/3/22
- 官方Events.GameCoreEventPublishComplete计时
- 该接口使用由“号码菌”带佬分享
- 总之虽然代码是大家自行安排，但个建议该Remove时务必Remove
- 注意该Events官方案例都是UI环境的lua，暂不确定Game环境是否可用
- 下面是就此Events接口，皮凯的的实操例子
### 具体例子
#### 构造计时循环
- 例如你希望这个函数每10秒运行一次
```lua
-- 因为GameCoreEventPublishComplete会每秒60次无限循环运行你添加的函数，所以10秒需要*60
local timing = 10 * 60
function function1()
    timing = timing - 1; --当 timing = 0时既10秒已过
    if timing == 0 then
        --省略你具体每10秒要工作的代码程序
        timing = 10 * 60； -- 重置时间
    end
end

function function2()-- 当需要function1这个循环函数工作时，触发function2()，添加function1
    Events.GameCoreEventPublishComplete.Add(function1)
end

function function3() -- 当不需要function1这个循环函数工作时，触发function3()，结束function1
    Events.GameCoreEventPublishComplete.Add(function1)
end
```
#### 定时器
- 例如你希望这个函数延迟10秒后运行
```lua
local timing = 10 * 60
function function1()
    timing = timing - 1; --当 timing = 0时既10秒已过
    if timing == 0 then
        --省略你具体延迟10秒后要运行的代码程序
        Events.GameCoreEventPublishComplete.Remove(function1) -- GameCoreEventPublishComplete里删除该函数，否则会一种运行它，增加没有必要的游戏运算
    end
end

function function2()-- 当需要function1这个定时器函数工作时，触发function2()，添加function1
    Events.GameCoreEventPublishComplete.Add(function1)
end

function function3() -- 当需要打断function1这个定时器函数工作时，触发function3()，结束function1
    Events.GameCoreEventPublishComplete.Add(function1)
end
```
#### 计时器框架
- 如果你的mod很多地方用到计时器为了节省写重复的代码那么你可以使用它
- 在这里皮凯提供一个较为完善的框架
```lua
-- TimeInSeconds需要定时执行的函数和对应时间
-- callbackFunc被延迟/循环的函数
-- loop是则为循环函数，不是或为nil则函数为延迟函数
-- FuncID用于额外的Remove停止循环/延时函数，记得不要为大于0的整数，给予其他字符串
CallbackDict = {};
AuxiliaryTiming = {};
ATnum = 0;

function AddTimer(TimeInSeconds, callbackFunc, loop, FuncID, Values)
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
    AuxiliaryTiming[FuncID] = TimeInSeconds;

    
    -- callbackFunc插入到定时循环中
    local function CreateLoopFunc()
        return function()
            AuxiliaryTiming[FuncID] = AuxiliaryTiming[FuncID] - 1;
            if AuxiliaryTiming[FuncID] == 0 then
                callbackFunc(Values);
                AuxiliaryTiming[FuncID] = TimeInSeconds;
            end
        end
    end

    -- callbackFunc插入到延时触发中
    local function CreateFunc()
        return function()
            AuxiliaryTiming[FuncID] = AuxiliaryTiming[FuncID] - 1;
            if AuxiliaryTiming[FuncID] == 0 then
                callbackFunc(Values);
                Events.GameCoreEventPublishComplete.Remove(CreateFunc());
                CallbackDict[FuncID] = nil;
            end
        end
    end

    local func = loop and CreateLoopFunc() or CreateFunc();
    Events.GameCoreEventPublishComplete.Add(func);
    
    -- 直接构造好对应的关闭循环的函数，亦或者提前关闭延迟的函数以免找不到对应func
    CallbackDict[FuncID] = function()
        Events.GameCoreEventPublishComplete.Remove(func);
        CallbackDict[FuncID] = nil;
    end
    return ATnum;
end
-- 这里主要还是关闭循环的函数，亦或者提前关闭延迟的函数，
-- 如果不需要这个功能请看后续删减版本
function RemoveTimer(FuncID)
    CallbackDict[FuncID](); 
end
--------------------------------------
-- 接下来就是框架被使用，
-- 建议作为一个基础性的lua脚本然后被使用
-- 两种跨lua文件使用方法
-- 直接LuaEvents或者是include(这个lua脚本)
-- 我个人推荐是include
-- 因为我不确定luaevent函数传过去一定正常工作
-- 相当于你函数作为参数跑另一个lua房间不确定能否正常调动原lua文件独有的东西
-- include是肯定稳的，总之如果你是使用直接LuaEvents方法麻烦和我说一下情况


-- 这个我感觉没必要直接，但还是讲一下
-- XXXAddTimer改成你独有id因为LuaEvents.这里ID是跨UILUA文件互通的，以免相同冲突
LuaEvents.XXXAddTimer.Add(AddTimer)
LuaEvents.XXXRemoveTimer.Add(AddTimer)
-- 当你在其他lua文件或使用该框架例子如下
LuaEvents.XXXAddTimer(180, function() print("4秒循环") end, true, "SSS"); -- 循环函数
LuaEvents.XXXAddTimer(1200, function() print("20秒后执行"); LuaEvents.XXXRemoveTimer("SSS"); end, false, "AAA"); -- 延时函数

-- 而include了直接引用XXXAddTimer和XXXRemoveTimer函数

--------------------------------------
-- 这里额外讲述一下Values的使用：
-- 1. 首先Values可以为空(nil)，但这样会给予callbackFunc一个nil参数
   -- 所以要确保你的callbackFunc要么一开始就不需要参数，要么能接受nil参数，不会导致什么BUG产生
-- 2. 然后Values是作为函数参数传递的，它可以是一个参数直接给予callbackFunc使用
-- 3. 但如果你需要给予callbackFunc多个参数，那么Values应当作为一个table，
   -- 你只需要直接这个table按顺序填入要给予callbackFunc的多个参数，然后在callbackFunc函数里有对应的处理方法
   -- 例如：
   -- function Func(Values)
   --     local a,b = Values[1],Values[2]; -- 简单的直接对应的处理方法
   --     print(a,b)
   -- end
```
![输入图片说明](%E8%AE%A1%E6%97%B6%E5%99%A8%E6%B5%8B%E8%AF%95mod/1image.png)

- 最后补充，你可以根据自己实际需求更改
- 例如你不需要额外的结束循环，你需要它一直工作，你可以删除CallbackDict和FuncID相关的
- 例子如下
```lua
-- TimeInSeconds需要定时执行的函数和对应时间
-- callbackFunc被延迟/循环的函数
-- loop是则为循环函数，不是或为nil则函数为延迟函数
AuxiliaryTiming = {};
ATnum = 0;

function AddTimer(TimeInSeconds, callbackFunc, loop)
    ATnum = ATnum + 1;
    -- 如果loop为nil
    loop = loop or false;

    -- callbackFunc插入到定时循环中
    local function CreateLoopFunc()
        return function()
            AuxiliaryTiming[ATnum] = AuxiliaryTiming[ATnum] - 1;
            if AuxiliaryTiming[ATnum] == 0 then
                callbackFunc();
                AuxiliaryTiming[ATnum] = TimeInSeconds;
            end
        end
    end

    -- callbackFunc插入到延时触发中
    local function CreateFunc()
        return function()
            AuxiliaryTiming[ATnum] = AuxiliaryTiming[ATnum] - 1;
            if AuxiliaryTiming[ATnum] == 0 then
                callbackFunc();
                Events.GameCoreEventPublishComplete.Remove(CreateFunc());
                CallbackDict[ATnum] = nil;
            end
        end
    end

    local func = loop and CreateLoopFunc() or CreateFunc();
    Events.GameCoreEventPublishComplete.Add(func);
end
```
- 总之结合自己需求，甚至你只需求延时，那么你完全可以删除循环亦或者你已经完成lua代码确保不会填错参数，那么关于我上面代码参数报错部分可以删除
## 总结，
- 两种方法都准时的,结合实际自行选择
- 暂时没有考虑存档退出游戏情况下，自动被清除的“在运行中的计时器的函数”在重新加载存档的情况如何自动重新启动，我个人暂时不需要这个功能，你可以使用SetProperty自行改进我的代码，也欢迎来找我进行交流，或者加入我这个项目
### UI控件计时优缺点
- 最大优点是可以直接修改动画控件速度(“SetSpeed”)
- 你如果本身就是UImod，动画控件计时也是方便的
- 缺点难以并发，例如希望两个动画控件同步开始
### Events计时器优缺点
- 便利性不用设置UI控件，直接可以用
- 很有可能实现并发，或者减小并发误差
- 缺点速度固定，如果希望超越1秒60次是无法达到，只能是1/60秒正整数倍数秒运行一次

## 热烈欢迎各路带佬参与到俺的文明6总结项目里
1. 可以Fork 本项目
2. 新建分支
3. 提交代码
- 联系我的方式，QQ群519747236/QQ频道-频道号: h4g7x81cj7/还可以[哔哩联系俺](https://space.bilibili.com/1440305287)

## 传送门
- [皮凯文明6总结(PK-CIV6)](https://gitee.com/XPPK/pk-civ6)
