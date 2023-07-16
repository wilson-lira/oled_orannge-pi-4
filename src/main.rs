use std::env;
use linux_embedded_hal::I2cdev;

use ssd1306::{prelude::*, I2CDisplayInterface, Ssd1306};
use embedded_graphics::{
    mono_font::{
        MonoTextStyleBuilder,
        ascii::FONT_8X13_BOLD,
    },
    text::{
        Text,
        Baseline
    },
    prelude::Point,
    Drawable,
    pixelcolor::BinaryColor
};

fn main() {
    let args: Vec<String> = env::args().collect();
    
    let empty = "".to_string();
    let line1 =  args.get(1).unwrap_or(&empty);
    let line2 =  args.get(2).unwrap_or(&empty);

    let i2c = I2cdev::new("/dev/i2c-8").unwrap();
    let interface = I2CDisplayInterface::new(i2c);
    let mut display = Ssd1306::new(
        interface,
        DisplaySize128x32,
        DisplayRotation::Rotate0,
    ).into_buffered_graphics_mode();

    display.init().unwrap();
    
    let text_style = MonoTextStyleBuilder::new()
        .font(&FONT_8X13_BOLD)
        .text_color(BinaryColor::On)
        .build();
    
    Text::with_baseline(&line1, Point::zero(), text_style, Baseline::Top)
        .draw(&mut display)
        .unwrap();
    
    Text::with_baseline(&line2, Point::new(0, 14), text_style, Baseline::Top)
        .draw(&mut display)
        .unwrap();
    
    display.flush().unwrap();

}

