-- main.lua
--[[
  Tower Defense Demo на LÖVE с выбором башен, ограничением размещения, усиленным уроном и анимацией снарядов.
  
  Основные изменения:
    1. Добавлен выбор башен через интерфейс в нижней панели.
    2. Реализована проверка: нельзя строить башни на тропе.
    3. Для каждого типа башен изменён внешний вид и цвет.
    4. Изменены параметры башен для достаточного урона.
    5. Добавлена анимация снарядов (для типов 1, 2, 4 – движущиеся снаряды; для типа 3 – луч, действующий короткое время).
]]--

-- Таблица настроек для каждого типа башен
towerSettings = {
    [1] = { fireRate = 0.5, damage = 40,  range = 120, areaRadius = 50 },   -- Быстрая стрельба, сильный одиночный урон
    [2] = { fireRate = 1.0, damage = 35,  range = 110, areaRadius = 70 },   -- Областьный урон
    [3] = { fireRate = 0.1, damage = 30,  range = 130 },                   -- Луч, наносящий постоянный урон
    [4] = { fireRate = 2.0, damage = 100, range = 130, areaRadius = 50 },    -- Медленная, но мощная башня
}

function love.load()
    love.window.setTitle("Tower Defense Demo")
    love.window.setMode(800, 600)  -- размеры окна: 800x600 пикселей

    -- Инициализация игровых переменных
    gameState = "menu"  -- "menu", "playing", "gameover"
    money = 100         -- стартовый капитал игрока
    life = 10           -- жизни игрока
    waveNumber = 0      -- номер текущей волны
    waveTimer = 40      -- интервал между волнами (сек)
    enemies = {}        -- таблица монстров
    towers = {}         -- таблица башен
    projectiles = {}    -- таблица снарядов

    -- Определяем тропу как список точек (x, y), по которым движутся монстры
    path = {
        {x = 50,  y = 300},
        {x = 200, y = 300},
        {x = 200, y = 150},
        {x = 400, y = 150},
        {x = 400, y = 400},
        {x = 600, y = 400},
        {x = 600, y = 250},
        {x = 750, y = 250},
    }

    -- Кнопка "Старт" в меню
    startButton = {x = 350, y = 250, width = 100, height = 50, text = "VOVA STARTUY START START START"}

    -- Интерфейс выбора башен в нижней панели
    towerButtons = {
        {type = 1, x = 600, y = 560, width = 40, height = 40, label = "1"},
        {type = 2, x = 650, y = 560, width = 40, height = 40, label = "2"},
        {type = 3, x = 700, y = 560, width = 40, height = 40, label = "3"},
        {type = 4, x = 750, y = 560, width = 40, height = 40, label = "4"},
    }
    selectedTowerType = 1  -- по умолчанию выбрана башня типа 1
end

-- Функция для расчёта расстояния от точки (px,py) до отрезка (x1,y1)-(x2,y2)
local function pointLineDistance(px, py, x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    local t = ((px - x1) * dx + (py - y1) * dy) / (dx * dx + dy * dy)
    if t < 0 then
        dx = px - x1
        dy = py - y1
    elseif t > 1 then
        dx = px - x2
        dy = py - y2
    else
        local projX = x1 + t * dx
        local projY = y1 + t * dy
        dx = px - projX
        dy = py - projY
    end
    return math.sqrt(dx * dx + dy * dy)
end

-- Проверка, находится ли точка (x,y) на тропе (с отступом threshold)
function isOnPath(x, y)
    local threshold = 20
    for i = 1, #path - 1 do
        local p1 = path[i]
        local p2 = path[i+1]
        if pointLineDistance(x, y, p1.x, p1.y, p2.x, p2.y) < threshold then
            return true
        end
    end
    return false
end

-- Спавн новой волны монстров
function spawnWave()
    waveNumber = waveNumber + 1
    for i = 1, 5 + waveNumber do
        local enemy = {
            x = path[1].x,
            y = path[1].y,
            speed = 50,
            pathIndex = 1,
            health = 100 + (waveNumber - 1) * 20,
        }
        table.insert(enemies, enemy)
    end
end

-- Обновление движения монстров по тропе
function updateEnemies(dt)
    for i = #enemies, 1, -1 do
        local enemy = enemies[i]
        if enemy.pathIndex >= #path then
            life = life - 1
            table.remove(enemies, i)
        else
            local target = path[enemy.pathIndex + 1]
            local dx = target.x - enemy.x
            local dy = target.y - enemy.y
            local dist = math.sqrt(dx * dx + dy * dy)
            if dist > 0 then
                local nx = dx / dist
                local ny = dy / dist
                enemy.x = enemy.x + nx * enemy.speed * dt
                enemy.y = enemy.y + ny * enemy.speed * dt
                if dist < enemy.speed * dt then
                    enemy.pathIndex = enemy.pathIndex + 1
                end
            end
        end
    end
end

-- Функция для создания снаряда от башни к цели
function spawnProjectile(tower, enemy)
    local proj = {
        x = tower.x,
        y = tower.y,
        target = enemy,  -- ссылка на цель
        type = tower.type,
        damage = tower.damage,
        areaRadius = tower.areaRadius,
        source = {x = tower.x, y = tower.y},  -- для отрисовки луча (типа 3)
    }
    -- Задаём скорость в зависимости от типа башни
    if tower.type == 1 then
        proj.speed = 300
    elseif tower.type == 2 then
        proj.speed = 250
    elseif tower.type == 4 then
        proj.speed = 150
    elseif tower.type == 3 then
        -- Для луча: не перемещается, действует 0.2 сек
        proj.speed = 0
        proj.duration = 0.2
        proj.timer = 0
    end
    table.insert(projectiles, proj)
end

-- Обновление логики башен: вместо прямого нанесения урона создаём снаряд
function updateTowers(dt)
    for _, tower in ipairs(towers) do
        tower.cooldown = tower.cooldown - dt
        if tower.cooldown <= 0 then
            -- Ищем первую цель в зоне башни
            for _, enemy in ipairs(enemies) do
                local dx = enemy.x - tower.x
                local dy = enemy.y - tower.y
                local distance = math.sqrt(dx * dx + dy * dy)
                if distance < tower.range then
                    spawnProjectile(tower, enemy)
                    tower.cooldown = tower.fireRate
                    break
                end
            end
        end
    end
end

-- Обновление снарядов
function updateProjectiles(dt)
    for i = #projectiles, 1, -1 do
        local proj = projectiles[i]
        if proj.type == 3 then
            -- Для луча: наносим непрерывный урон в течение длительности
            proj.timer = proj.timer + dt
            if proj.target and proj.target.health then
                proj.target.health = proj.target.health - proj.damage * dt
            end
            if proj.timer >= proj.duration then
                table.remove(projectiles, i)
            end
        else
            -- Для обычных снарядов: проверяем, существует ли цель
            if not proj.target or proj.target.health <= 0 then
                table.remove(projectiles, i)
            else
                local dx = proj.target.x - proj.x
                local dy = proj.target.y - proj.y
                local dist = math.sqrt(dx * dx + dy * dy)
                if dist < 10 then
                    -- При попадании снаряда наносим урон
                    if proj.type == 2 then
                        -- Областьный урон: поражаем всех врагов в зоне
                        for _, e in ipairs(enemies) do
                            local ex = e.x - proj.x
                            local ey = e.y - proj.y
                            local d = math.sqrt(ex * ex + ey * ey)
                            if d < proj.areaRadius then
                                e.health = e.health - proj.damage * 0.8
                            end
                        end
                    else
                        proj.target.health = proj.target.health - proj.damage
                    end
                    table.remove(projectiles, i)
                else
                    -- Двигаем снаряд к цели
                    local nx = dx / dist
                    local ny = dy / dist
                    proj.x = proj.x + nx * proj.speed * dt
                    proj.y = proj.y + ny * proj.speed * dt
                end
            end
        end
    end
end

-- Отрисовка снарядов
function drawProjectiles()
    for _, proj in ipairs(projectiles) do
        if proj.type == 1 then
            -- Зеленый снаряд для башни типа 1
            love.graphics.setColor(0, 1, 0)
            love.graphics.circle("fill", proj.x, proj.y, 5)
        elseif proj.type == 2 then
            -- Синий снаряд для башни типа 2
            love.graphics.setColor(0, 0, 1)
            love.graphics.circle("fill", proj.x, proj.y, 5)
        elseif proj.type == 4 then
            -- Красный, медленный снаряд для башни типа 4
            love.graphics.setColor(1, 0, 0)
            love.graphics.circle("fill", proj.x, proj.y, 7)
        elseif proj.type == 3 then
            -- Для луча: рисуем линию от башни до цели
            if proj.target then
                love.graphics.setColor(1, 1, 0)
                love.graphics.setLineWidth(3)
                love.graphics.line(proj.source.x, proj.source.y, proj.target.x, proj.target.y)
            end
        end
    end
    love.graphics.setColor(1, 1, 1)
end

-- Отрисовка интерфейса (нижняя панель)
function drawInterface()
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", 0, 550, 800, 50)
    love.graphics.setColor(0, 0, 0)
    love.graphics.print("money: " .. money, 10, 560)
    love.graphics.print("life: " .. life, 150, 560)
    love.graphics.print("wave: " .. waveNumber, 300, 560)
    love.graphics.print("next wave: " .. math.floor(waveTimer), 450, 560)

    -- Кнопки выбора башен
    for _, btn in ipairs(towerButtons) do
        if selectedTowerType == btn.type then
            love.graphics.setColor(0.8, 0.8, 0.8)
            love.graphics.rectangle("fill", btn.x - 2, btn.y - 2, btn.width + 4, btn.height + 4)
        end
        love.graphics.setColor(0.9, 0.9, 0.9)
        love.graphics.rectangle("fill", btn.x, btn.y, btn.width, btn.height)
        love.graphics.setColor(0, 0, 0)
        love.graphics.printf(btn.label, btn.x, btn.y + 12, btn.width, "center")
    end
end

-- Отрисовка тропы
function drawPath()
    love.graphics.setColor(0.5, 0.5, 0.5)
    for i = 1, #path - 1 do
        love.graphics.setLineWidth(20)
        love.graphics.line(path[i].x, path[i].y, path[i+1].x, path[i+1].y)
    end
end

-- Отрисовка башен с разным видом
function drawTowers()
    for _, tower in ipairs(towers) do
        if tower.type == 1 then
            love.graphics.setColor(0, 1, 0)
            love.graphics.rectangle("fill", tower.x - 15, tower.y - 15, 30, 30)
        elseif tower.type == 2 then
            love.graphics.setColor(0, 0, 1)
            love.graphics.polygon("fill",
                tower.x, tower.y - 16,
                tower.x - 14, tower.y + 14,
                tower.x + 14, tower.y + 14
            )
        elseif tower.type == 3 then
            love.graphics.setColor(1, 1, 0)
            love.graphics.circle("fill", tower.x, tower.y, 15)
            love.graphics.setColor(0.8, 0.8, 0)
            love.graphics.circle("line", tower.x, tower.y, 18)
        elseif tower.type == 4 then
            love.graphics.setColor(1, 0, 0)
            love.graphics.rectangle("fill", tower.x - 15, tower.y - 15, 30, 30)
            love.graphics.setColor(0, 0, 0)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", tower.x - 15, tower.y - 15, 30, 30)
        end
        love.graphics.setColor(1, 1, 1)
    end
end

-- Отрисовка монстров
function drawEnemies()
    love.graphics.setColor(1, 0, 1)
    for _, enemy in ipairs(enemies) do
        love.graphics.rectangle("fill", enemy.x - 10, enemy.y - 10, 20, 20)
    end
    love.graphics.setColor(1, 1, 1)
end

-- Основной цикл обновления игры
function love.update(dt)
    if gameState == "playing" then
        waveTimer = waveTimer - dt
        if waveTimer <= 0 then
            spawnWave()
            waveTimer = 40
        end
        updateEnemies(dt)
        updateTowers(dt)
        updateProjectiles(dt)
        if life <= 0 then
            gameState = "gameover"
        end
    end
end

-- Основной цикл отрисовки
function love.draw()
    if gameState == "menu" then
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.rectangle("fill", startButton.x, startButton.y, startButton.width, startButton.height)
        love.graphics.setColor(0, 0, 0)
        love.graphics.printf(startButton.text, startButton.x, startButton.y + 15, startButton.width, "center")
    elseif gameState == "playing" or gameState == "gameover" then
        love.graphics.setBackgroundColor(0.2, 0.2, 0.2)
        drawPath()
        drawTowers()
        drawEnemies()
        drawProjectiles()
        drawInterface()
        if gameState == "gameover" then
            love.graphics.setColor(1, 0, 0)
            love.graphics.printf("gameover!", 0, 300, 800, "center")
        end
    end
end

-- Обработка кликов мыши
function love.mousepressed(x, y, button)
    if gameState == "menu" then
        if x >= startButton.x and x <= startButton.x + startButton.width and
           y >= startButton.y and y <= startButton.y + startButton.height then
            gameState = "playing"
        end
    elseif gameState == "playing" then
        -- Проверка нажатия на кнопки выбора башен
        for _, btn in ipairs(towerButtons) do
            if x >= btn.x and x <= btn.x + btn.width and
               y >= btn.y and y <= btn.y + btn.height then
                selectedTowerType = btn.type
                return
            end
        end

        -- Постройка башни в игровой области (выше нижней панели)
        if y < 550 then
            if isOnPath(x, y) then
                print("Нельзя строить башню на тропе!")
                return
            end

            local cost = 20
            if money >= cost then
                money = money - cost
                local settings = towerSettings[selectedTowerType]
                local tower = {
                    x = x,
                    y = y,
                    type = selectedTowerType,
                    fireRate = settings.fireRate,
                    cooldown = 0,
                    damage = settings.damage,
                    range = settings.range,
                    areaRadius = settings.areaRadius or 0,
                }
                table.insert(towers, tower)
            end
        end
    end
end

function love.keypressed(key)
    -- Дополнительная логика, если потребуется
end
