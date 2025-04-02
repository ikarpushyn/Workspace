function love.load()

    -- Таблица для хранения всех юнитов
    local units = {}

    game = {
        wave = 1,
        waveTimer = 0,
        waveInterval = 5,
        spawnPoint = {
            x = 50,
            y = 300
        },
        basePosition = {
            x = 900,
            y = 300
        }, -- Сдвинули базу дальше
        field = {
            x = 20,
            y = 20,
            width = 984,
            height = 728, -- Поле с отступами 20px от краев
            color = {0.15, 0.15, 0.15} -- Темно-серый цвет поля
        },
        projectiles = {} -- Таблица для снарядов
    }

    units[1] = {
        type = "knight",
        x = game.spawnPoint.x,
        y = game.spawnPoint.y,
        speed = 60,
        health = 100,
        color = {0.8, 0.8, 0.8} -- Светло-серый
    }

    units[2] = {
        type = "archer",
        x = game.spawnPoint.x,
        y = game.spawnPoint.y + 50,
        speed = 80,
        health = 70,
        color = {0.3, 0.6, 0.3}, -- Зеленый
        attackTimer = 0,
        attackInterval = 1.5 -- Стреляет каждые 1.5 секунды
    }

    game.units = units
end

function love.update(dt)
    game.waveTimer = game.waveTimer + dt

    if game.waveTimer >= game.waveInterval then
        spawnWave()
        game.waveTimer = 0
        game.wave = game.wave + 1
    end

    -- Обновление позиций юнитов и стрельба
    for i, unit in ipairs(game.units) do
        local dx = game.basePosition.x - unit.x
        local dy = game.basePosition.y - unit.y
        local distance = math.sqrt(dx ^ 2 + dy ^ 2)

        if distance > 0 then
            unit.x = unit.x + (dx / distance) * unit.speed * dt
            unit.y = unit.y + (dy / distance) * unit.speed * dt
        end

        -- Логика стрельбы для лучников
        if unit.type == "archer" then
            unit.attackTimer = unit.attackTimer + dt
            if unit.attackTimer >= unit.attackInterval then
                -- Создаем стрелу
                table.insert(game.projectiles, {
                    x = unit.x + 15, -- Центр юнита
                    y = unit.y + 15,
                    targetX = game.basePosition.x + 25, -- Центр базы
                    targetY = game.basePosition.y + 25,
                    speed = 400,
                    color = {1, 0.8, 0} -- Желтый
                })
                unit.attackTimer = 0
            end
        end
    end

    -- Обновление позиций снарядов
    for i = #game.projectiles, 1, -1 do
        local p = game.projectiles[i]
        local dx = p.targetX - p.x
        local dy = p.targetY - p.y
        local distance = math.sqrt(dx ^ 2 + dy ^ 2)

        if distance < 5 then -- Снаряд достиг цели
            table.remove(game.projectiles, i)
        else
            p.x = p.x + (dx / distance) * p.speed * dt
            p.y = p.y + (dy / distance) * p.speed * dt
        end
    end
end

function love.draw()
    -- Фон игрового поля
    love.graphics.setColor(game.field.color)
    love.graphics.rectangle("fill", game.field.x, game.field.y, game.field.width, game.field.height)

    -- Границы поля (белая рамка)
    love.graphics.setColor(1, 1, 1)
    love.graphics
        .rectangle("line", game.field.x, game.field.y, game.field.width, game.field.height, 3 -- Толщина линии
    )

    -- База (красная)
    love.graphics.setColor(1, 0.2, 0.2)
    love.graphics.rectangle("fill", game.basePosition.x, game.basePosition.y, 50, 50)

    -- Юниты
    for i, unit in ipairs(game.units) do
        love.graphics.setColor(unit.color)
        love.graphics.rectangle("fill", unit.x, unit.y, 30, 30)
        love.graphics.print(unit.type, unit.x, unit.y - 20)

        -- Полоска здоровья
        love.graphics.setColor(0.2, 0.8, 0.2)
        love.graphics
            .rectangle("fill", unit.x, unit.y - 10, unit.health / 3, 3 -- Ширина зависит от здоровья
        )
    end

    -- Снаряды (стрелы)
    for i, p in ipairs(game.projectiles) do
        love.graphics.setColor(p.color)
        love.graphics.line(p.x, p.y, p.x + 20, p.y) -- Горизонтальная линия
    end

    -- UI
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Wave: " .. game.wave, 10, 10)
    love.graphics.print("Next wave in: " .. math.floor(game.waveInterval - game.waveTimer), 10, 30)
end

function spawnWave()
    for i = 1, 2 do
        table.insert(game.units, {
            type = "knight",
            x = game.spawnPoint.x,
            y = game.spawnPoint.y + i * 60,
            speed = 60,
            health = 100,
            color = {0.8, 0.8, 0.8}
        })
    end
end
