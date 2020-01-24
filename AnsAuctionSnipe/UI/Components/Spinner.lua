SpinnerMixin = {};
SpinnerMixin.__index = SpinnerMixin;
SpinnerMixin.isReady = false;

function SpinnerMixin:Init()
    if (self.isReady) then
        return;
    end

    self.isReady = true;
    self.SpinnerAnim:Play();
end