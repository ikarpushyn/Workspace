--[[ 
  Аналог "use strict" в JavaScript: 
  всегда объявляйте переменные через "local", чтобы избежать глобальных утечек.
]] function love.load()
    -- Таблица для хранения всех юнитов (аналог массива объектов в JS)
    local units = {}

    -- Базовые параметры игры
    game = {
        wave = 1,
        waveTimer = 0,
        waveInterval = 5, -- Упростим до 5 секунд для теста
        spawnPoint = {
            x = 50,
            y = 300
        }, -- Точка спавна юнитов
        basePosition = {
            x = 700,
            y = 300
        } -- Цель для атаки
    }

    -- Создаем двух юнитов (пока без спрайтов)
    -- Это как объявить объекты в JS: { type: 'knight', x: 100, ... }
    units[1] = {
        type = "knight",
        x = game.spawnPoint.x,
        y = game.spawnPoint.y,
        speed = 60,
        health = 100
    }

    units[2] = {
        type = "archer",
        x = game.spawnPoint.x,
        y = game.spawnPoint.y + 50, -- Смещение, чтобы юниты не накладывались
        speed = 80,
        health = 70
    }

    -- Сохраняем юниты в глобальную переменную (временно)
    game.units = units
end

function love.update(dt)
    -- Обновляем таймер волны
    game.waveTimer = game.waveTimer + dt

    -- Спавн новой волны
    if game.waveTimer >= game.waveInterval then
        spawnWave()
        game.waveTimer = 0
        game.wave = game.wave + 1
    end

    -- Движение всех юнитов к базе
    for i, unit in ipairs(game.units) do
        -- Рассчитываем направление
        local dx = game.basePosition.x - unit.x
        local dy = game.basePosition.y - unit.y
        local distance = math.sqrt(dx ^ 2 + dy ^ 2)

        -- Нормализуем вектор (аналог dx / distance в JS)
        if distance > 0 then
            unit.x = unit.x + (dx / distance) * unit.speed * dt
            unit.y = unit.y + (dy / distance) * unit.speed * dt
        end
    end
end

function love.draw()
    -- Рисуем базу
    love.graphics.rectangle("fill", game.basePosition.x, game.basePosition.y, 50, 50)

    -- Рисуем юнитов
    for i, unit in ipairs(game.units) do
        love.graphics.setColor(1, 1, 1) -- Белый цвет
        love.graphics.rectangle("fill", unit.x, unit.y, 30, 30) -- Квадрат вместо спрайта
        love.graphics.print(unit.type, unit.x, unit.y - 20) -- Текст с типом юнита
    end

    -- UI: Таймер волны
    love.graphics.print("Wave: " .. game.wave, 10, 10)
    love.graphics.print("Next wave in: " .. math.floor(game.waveInterval - game.waveTimer), 10, 30)
end

-- Кастомная функция для спавна волны
function spawnWave()
    -- Добавляем новых юнитов (пока без баланса)
    for i = 1, 2 do
        table.insert(game.units, {
            type = "knight",
            x = game.spawnPoint.x,
            y = game.spawnPoint.y + i * 60, -- Смещение по Y
            speed = 60,
            health = 100
        })
    end
end
