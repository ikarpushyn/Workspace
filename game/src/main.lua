function love.load()
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
        },
        base = {
            health = 1000,
            maxHealth = 1000,
            attackTimer = 0,
            attackInterval = 1,
            projectiles = {}
        },
        field = {
            x = 20,
            y = 20,
            width = 984,
            height = 728,
            color = {0.15, 0.15, 0.15}
        },
        projectiles = {},
        panel = {
            y = 650,
            height = 80,
            buttons = {{
                type = "knight",
                x = 100,
                width = 100,
                height = 50,
                color = {0.8, 0.8, 0.8}
            }, {
                type = "archer",
                x = 250,
                width = 100,
                height = 50,
                color = {0.3, 0.6, 0.3}
            }}
        },
        resetButton = {
            x = 900,
            y = 10,
            width = 80,
            height = 30,
            color = {0.7, 0.2, 0.2}
        },
        sprites = { -- Добавляем спрайты
            knight = love.graphics.newImage("assets/sprites/knight.png")

        },
        gameOver = false -- Флаг окончания игры
    }

    units[1] = {
        type = "knight",
        x = game.spawnPoint.x,
        y = game.spawnPoint.y,
        speed = 60,
        health = 100,
        damage = 10,
        attackRange = 40,
        attackTimer = 0,
        attackInterval = 1,
        color = {0.8, 0.8, 0.8},
        isPlayerUnit = false
    }

    units[2] = {
        type = "archer",
        x = game.spawnPoint.x,
        y = game.spawnPoint.y + 50,
        speed = 80,
        health = 70,
        damage = 5,
        attackRange = 200,
        attackTimer = 0,
        attackInterval = 1.5,
        color = {0.3, 0.6, 0.3},
        animation = {
            frame = 0,
            speed = 2
        },
        isPlayerUnit = false
    }

    game.units = units
end

function love.update(dt)
    if game.gameOver then
        return -- Прекращаем обновление игры, если она завершена
    end

    game.waveTimer = game.waveTimer + dt

    if game.waveTimer >= game.waveInterval then
        spawnWave()
        game.waveTimer = 0
        game.wave = game.wave + 1
    end

    for i = #game.units, 1, -1 do
        local unit = game.units[i]
        local dx = game.basePosition.x - unit.x
        local dy = game.basePosition.y - unit.y
        local distance = math.sqrt(dx ^ 2 + dy ^ 2)

        if distance > unit.attackRange then
            unit.x = unit.x + (dx / distance) * unit.speed * dt
            unit.y = unit.y + (dy / distance) * unit.speed * dt
        end

        unit.attackTimer = unit.attackTimer + dt
        if unit.attackTimer >= unit.attackInterval then
            if distance <= unit.attackRange then
                game.base.health = game.base.health - unit.damage
                unit.attackTimer = 0
            elseif unit.type == "archer" then
                table.insert(game.projectiles, {
                    x = unit.x + 15,
                    y = unit.y + 15,
                    targetX = game.basePosition.x + 25,
                    targetY = game.basePosition.y + 25,
                    speed = 400,
                    damage = unit.damage,
                    color = {1, 0.8, 0}
                })
                unit.animation.frame = 1
                unit.attackTimer = 0
            end
        end

        if unit.type == "archer" then
            if unit.attackTimer < unit.attackInterval * 0.7 then
                unit.animation.frame = math.min(unit.animation.frame + dt * unit.animation.speed, 0.5)
            elseif unit.attackTimer >= unit.attackInterval then
                unit.animation.frame = 1
            else
                unit.animation.frame = math.max(unit.animation.frame - dt * unit.animation.speed, 0)
            end
        end

        if unit.health <= 0 then
            table.remove(game.units, i)
        end
    end

    for i = #game.projectiles, 1, -1 do
        local p = game.projectiles[i]
        local dx = p.targetX - p.x
        local dy = p.targetY - p.y
        local distance = math.sqrt(dx ^ 2 + dy ^ 2)

        if distance < 5 then
            game.base.health = game.base.health - p.damage
            table.remove(game.projectiles, i)
        else
            p.x = p.x + (dx / distance) * p.speed * dt
            p.y = p.y + (dy / distance) * p.speed * dt
        end
    end

    game.base.attackTimer = game.base.attackTimer + dt
    if game.base.attackTimer >= game.base.attackInterval and #game.units > 0 then
        local closestUnit = nil
        local minDistance = math.huge
        for _, unit in ipairs(game.units) do
            local dist = math.sqrt((unit.x - game.basePosition.x) ^ 2 + (unit.y - game.basePosition.y) ^ 2)
            if dist < minDistance then
                minDistance = dist
                closestUnit = unit
            end
        end

        if closestUnit then
            table.insert(game.base.projectiles, {
                x = game.basePosition.x + 25,
                y = game.basePosition.y + 25,
                targetX = closestUnit.x + 15,
                targetY = closestUnit.y + 15,
                speed = 300,
                damage = 20,
                color = {1, 0, 0}
            })
            game.base.attackTimer = 0
        end
    end

    for i = #game.base.projectiles, 1, -1 do
        local p = game.base.projectiles[i]
        local dx = p.targetX - p.x
        local dy = p.targetY - p.y
        local distance = math.sqrt(dx ^ 2 + dy ^ 2)

        if distance < 5 then
            for _, unit in ipairs(game.units) do
                local unitDist = math.sqrt((unit.x + 15 - p.x) ^ 2 + (unit.y + 15 - p.y) ^ 2)
                if unitDist < 15 then
                    unit.health = unit.health - p.damage
                    break
                end
            end
            table.remove(game.base.projectiles, i)
        else
            p.x = p.x + (dx / distance) * p.speed * dt
            p.y = p.y + (dy / distance) * p.speed * dt
        end
    end

    -- Проверка на окончание игры
    if game.base.health <= 0 then
        game.base.health = 0
        game.gameOver = true
    end
end

function love.draw()
    love.graphics.setColor(game.field.color)
    love.graphics.rectangle("fill", game.field.x, game.field.y, game.field.width, game.field.height)

    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", game.field.x, game.field.y, game.field.width, game.field.height, 3)

    love.graphics.setColor(1, 0.2, 0.2)
    love.graphics.rectangle("fill", game.basePosition.x, game.basePosition.y, 50, 50)
    love.graphics.setColor(0.2, 0.8, 0.2)
    love.graphics.rectangle("fill", game.basePosition.x, game.basePosition.y - 10,
        (game.base.health / game.base.maxHealth) * 50, 3)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(game.base.health .. "/" .. game.base.maxHealth, game.basePosition.x, game.basePosition.y - 30)

    for i, unit in ipairs(game.units) do
        love.graphics.setColor(unit.color)
        if unit.type == "archer" then
            love.graphics.rectangle("fill", unit.x, unit.y, 30, 30)
            love.graphics.setColor(0.6, 0.4, 0.2)
            local bowOffset = unit.animation.frame * 10
            love.graphics.line(unit.x + 30, unit.y, unit.x + 30, unit.y + 30)
            love.graphics.setColor(0.8, 0.8, 0.8)
            love.graphics.line(unit.x + 30, unit.y, unit.x + 30 - bowOffset, unit.y + 15, unit.x + 30, unit.y + 30)
        else
            love.graphics.draw(game.sprites.knight, unit.x, unit.y)
        end
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(unit.type, unit.x, unit.y - 20)
        if unit.isPlayerUnit then
            love.graphics.setColor(0, 0.5, 1)
        else
            love.graphics.setColor(0.2, 0.8, 0.2)
        end
        love.graphics.rectangle("fill", unit.x, unit.y - 10, unit.health / 3, 3)
    end

    for i, p in ipairs(game.projectiles) do
        love.graphics.setColor(p.color)
        love.graphics.line(p.x, p.y, p.x + 20, p.y)
    end

    for i, p in ipairs(game.base.projectiles) do
        love.graphics.setColor(p.color)
        love.graphics.line(p.x, p.y, p.x - 20, p.y)
    end

    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", 0, game.panel.y, love.graphics.getWidth(), game.panel.height)

    for _, button in ipairs(game.panel.buttons) do
        love.graphics.setColor(button.color)
        love.graphics.rectangle("fill", button.x, game.panel.y + 15, button.width, button.height)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(button.type, button.x, game.panel.y + 30, button.width, "center")
    end

    love.graphics.setColor(game.resetButton.color)
    love.graphics.rectangle("fill", game.resetButton.x, game.resetButton.y, game.resetButton.width,
        game.resetButton.height)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Reset", game.resetButton.x, game.resetButton.y + 10, game.resetButton.width, "center")

    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Wave: " .. game.wave, 10, 10)
    love.graphics.print("Next wave in: " .. math.floor(game.waveInterval - game.waveTimer), 10, 30)
    love.graphics.print("Base Health: " .. game.base.health .. "/" .. game.base.maxHealth, 10, 50)

    -- Отображение победы
    if game.gameOver then
        love.graphics.setColor(0, 0, 0, 0.7) -- Полупрозрачный черный фон
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.setColor(0, 1, 0) -- Зеленый цвет текста
        love.graphics.printf("Victory! You destroyed the citadel!", 0, love.graphics.getHeight() / 2 - 20,
            love.graphics.getWidth(), "center")
        love.graphics.printf("Click Reset to play again", 0, love.graphics.getHeight() / 2 + 20,
            love.graphics.getWidth(), "center")
    end
end

function spawnWave()
    for i = 1, 2 do
        table.insert(game.units, {
            type = "knight",
            x = game.spawnPoint.x,
            y = game.spawnPoint.y + i * 60,
            speed = 60,
            health = 100,
            damage = 10,
            attackRange = 40,
            attackTimer = 0,
            attackInterval = 1,
            color = {0.8, 0.8, 0.8},
            isPlayerUnit = false
        })
    end
end

function spawnPlayerUnit(unitType)
    local unit = {}
    if unitType == "knight" then
        unit = {
            type = "knight",
            x = game.spawnPoint.x,
            y = game.spawnPoint.y,
            speed = 60,
            health = 100,
            damage = 10,
            attackRange = 40,
            attackTimer = 0,
            attackInterval = 1,
            color = {0.8, 0.8, 0.8},
            isPlayerUnit = true
        }
    elseif unitType == "archer" then
        unit = {
            type = "archer",
            x = game.spawnPoint.x,
            y = game.spawnPoint.y,
            speed = 80,
            health = 70,
            damage = 5,
            attackRange = 200,
            attackTimer = 0,
            attackInterval = 1.5,
            color = {0.3, 0.6, 0.3},
            animation = {
                frame = 0,
                speed = 2
            },
            isPlayerUnit = true
        }
    end
    table.insert(game.units, unit)
end

function love.mousepressed(x, y, button)
    if button == 1 then
        if not game.gameOver then -- Спавн юнитов только если игра не окончена
            for _, btn in ipairs(game.panel.buttons) do
                if x >= btn.x and x <= btn.x + btn.width and y >= game.panel.y + 15 and y <= game.panel.y + 15 +
                    btn.height then
                    spawnPlayerUnit(btn.type)
                end
            end
        end
        -- Кнопка Reset работает всегда
        if x >= game.resetButton.x and x <= game.resetButton.x + game.resetButton.width and y >= game.resetButton.y and
            y <= game.resetButton.y + game.resetButton.height then
            resetGame()
        end
    end
end

function resetGame()
    game.wave = 1
    game.waveTimer = 0
    game.base.health = game.base.maxHealth
    game.base.attackTimer = 0
    game.units = {}
    game.projectiles = {}
    game.base.projectiles = {}
    game.gameOver = false -- Сбрасываем флаг окончания игры

    game.units[1] = {
        type = "knight",
        x = game.spawnPoint.x,
        y = game.spawnPoint.y,
        speed = 60,
        health = 100,
        damage = 10,
        attackRange = 40,
        attackTimer = 0,
        attackInterval = 1,
        color = {0.8, 0.8, 0.8},
        isPlayerUnit = false
    }
    game.units[2] = {
        type = "archer",
        x = game.spawnPoint.x,
        y = game.spawnPoint.y + 50,
        speed = 80,
        health = 70,
        damage = 5,
        attackRange = 200,
        attackTimer = 0,
        attackInterval = 1.5,
        color = {0.3, 0.6, 0.3},
        animation = {
            frame = 0,
            speed = 2
        },
        isPlayerUnit = false
    }
end
