with Ada.Unchecked_Conversion;
with System;
with Ada.Text_IO;
with GEM.AES; use GEM.AES;
with GEM.AES.Window; use GEM.AES.Window;
with GEM.AES.Event; use GEM.AES.Event;
with GEM.AES.Application; use GEM.AES.Application;
with GEM.AES.Graf; use GEM.AES.Graf;
with GEM.VDI; use GEM.VDI;
with TOS; use TOS;


procedure Lines is
    -- Data
    type Point is record
        x, y : Int16;
    end record;

    type Line is Record
        p1, p2  : Point;
        color   : Int16;
    end Record;

    Max_Trail : constant := 15;
    Trail     : array (1 .. Max_Trail) of Line :=
        (others => (p1 => (x => -1, y => -1),
                    p2 => (x => -1, y => -1),
                    others => 0));

    Colors    : constant array (1 .. Max_Trail) of Uint16 := (16#F800#,
                                                                        16#C000#,
                                                                        16#9000#,
                                                                        16#6000#,
                                                                        16#3000#,
                                                                        others => 0);

    -- Handles
    Vdi_Handle  : aliased Int16;
    Win         : GEM.AES.Window.Window_Handle;
    Work_Area   : aliased Rectangle;
    app_id      : App_Id_Type;

    procedure Update_Trail(New_Line : Line) is
    begin
        for i in reverse Trail'First + 1 .. Trail'Last loop
            Trail(i) := Trail(i - 1);
        end loop;
        Trail(1) := New_Line;
    end Update_Trail;

    procedure Draw_Trail is
        Points : Int16_Array_Type(0 .. 3);
    begin
        for i in Trail'First .. Trail'Last - 1 loop
            Set_Polyline_Color_Index(Vdi_Handle, 1);
            Points := (Trail(i).p1.x + Work_Area.x, Trail(i).p1.y + Work_Area.y,
                       Trail(i).p2.x + Work_Area.x, Trail(i).p2.y + Work_Area.y);
            GEM.VDI.Set_Polyline_Color_Index(Vdi_Handle, Trail(i).color);
            Polyline(Vdi_Handle, 2, Points);
            -- end if;
        end loop;
    end Draw_Trail;

    function Rect_Intersect(R1 : in Rectangle; R2 : in out Rectangle) return Boolean is
        tx, ty, tw, th      : Int16;
        Ret                 : Boolean;
    begin
        tx := Int16'Max(R2.x, R1.x);
        tw := Int16'Min(R2.x + R2.w, R1.x + R1.w) - tx;

        Ret := (0 < tw);

        if Ret then
            ty := Int16'Max(R2.y, R1.y);
            th := Int16'Min(R2.y + R2.h, R1.y + R1.h) - ty;

            Ret := (0 < th);

            if Ret then
                R2 := (tx, ty, tw, th);
            end if;
        end if;
        return Ret;
    end Rect_Intersect;

    procedure Redraw_Window is
        Clip    : Int16_Array_Type(1 .. 4);
        r       : aliased Rectangle;

    begin
        r := GEM.AES.Window.Get(Win, GEM.AES.Window.First_XYWH);

        while r.w > 0 and r.h > 0 loop
            if Rect_Intersect(Work_Area, r) then
                Clip := (r.x, r.y, r.x + r.w - 1, r.y + r.h - 1);
                GEM.VDI.Set_Clipping_Rectangle(Vdi_Handle, True, Clip);
                GEM.VDI.Set_Fill_Interior_Style(Vdi_Handle, Solid);
                GEM.VDI.Set_Fill_Color_Index(Vdi_Handle, 1);
                GEM.VDI.Fill_Rectangle(Vdi_Handle, Clip);
                Draw_Trail;
                GEM.VDI.Set_Clipping_Rectangle(Vdi_Handle, False, Clip);
            end if;
            r := GEM.AES.Window.Get(Win, GEM.AES.Window.Next_XYWH);
        end loop;
    end Redraw_Window;

    procedure Send_Redraw(Win : Window_Handle; r : Rectangle) is
        Message : Int16_Array_Type(0 .. 7) := (Int16(Window_Redraw_Msg), r.x, r.y, r.w, r.h, others => 0);
    begin
        GEM.AES.Application.Write(app_id, Message);
    end Send_Redraw;
    
    col     : Int16 := 0;
begin
    app_id := GEM.AES.Application.Init;
    declare
        Work_In  : Int16_Array_Type(0 .. 10) := (10 => 2, others => 1);
        Work_Out : Int16_Array_Type(0 .. 57);
        wc, hc, wb, hb : Int16 := 0;
    begin
        Vdi_Handle := GEM.AES.Graf.Handle(wc, hc, wb, hb);

        Open_Virtual_Screen_Workstation(Work_In, Vdi_Handle, Work_Out);
        GEM.AES.Graf.Mouse(Arrow);
    end;

    Win := GEM.AES.Window.Create(Namer + Closer + GEM.AES.Window.Mover + Fuller + Sizer, (50, 50, 320, 200));
    GEM.AES.Window.Set(Win, Name, "Lines");
    GEM.AES.Window.Open(Win, (50, 50, 320, 200));
    Work_Area := GEM.AES.Window.Get(Win, Current_XYWH);

    -- Main loop
    declare
        Msg         : aliased Message_Buffer;
        Msg_Ptr     : constant Message_Buffer_Ptr := Msg'Unchecked_Access;
        
        Quit        : Boolean := False;
        MX, MY      : Int16 := 0;
        Event       : Event_Type;
        p1          : Point := (10, 10);
        p2          : Point := (Work_Area.w - 10, Work_Area.h - 10);
        dx1         : Int16 := 3;
        dy1         : Int16 := 4;
        dx2         : Int16 := -3;
        dy2         : Int16 := -5;
        Button_Down : Int16;
        Timer_MS    : Long_Integer := 500;
        Mb_Return, Key_State, Key_Return, Ret : Int16;
        fulled      : Boolean := False;
    begin -- Lines
        loop
            p1.x := p1.x + dx1; if p1.x >= Work_Area.w or p1.x < 0 then dx1 := -dx1; end if;
            p1.y := p1.y + dy1; if p1.y >= Work_Area.h or p1.y < 0 then dy1 := -dy1; end if;
            p2.x := p2.x + dx2; if p2.x >= Work_Area.w or p2.x < 0 then dx2 := -dx2; end if;
            p2.y := p2.y + dy2; if p2.y >= Work_Area.h or p2.y < 0 then dy2 := -dy2; end if;
            if p1.x < 0 then p1.x := 0;
            elsif p1.x >= Work_Area.w then p1.x := Work_Area.w - 1;
            end if;
            if p2.x < 0 then p2.x := 0;
            elsif p2.x >= Work_Area.w then p2.x := Work_Area.w - 1;
            end if;
            
            if p1.y < 0 then p1.y := 0;
            elsif p1.y >= Work_Area.h then p1.y := Work_Area.h - 1;
            end if;

            if p2.y < 0 then p2.y := 0;
            elsif p2.y >= Work_Area.h then p2.y := Work_Area.h - 1;
            end if;
            
            Update_Trail((p1, p2, col));
            col := (col + 1) mod 255; if col = 0 then col := 16; end if;

            Event := GEM.AES.Event.Multi(Message_Event + Button_Event + Keyboard_Event + Timer_Event,
                                1, 1, Button_Down,
                                False, 0, 0, 0, 0,
                                False, 0, 0, 0, 0,
                                Msg_Ptr, Timer_MS, MX, MY,
                                Mb_Return, Key_State,
                                Key_Return, Ret);
            if Message_Type(Msg(0)) = Window_Redraw_Msg then
                GEM.AES.Window.Update(Update_Begin);
                Redraw_Window;
                GEM.AES.Window.Update(Update_End);
            elsif Message_Type(Msg(0)) = Window_Moved_Msg or
                  Message_Type(Msg(0)) = Window_Sized_Msg then
                GEM.AES.Window.Set(Win, Current_XYWH, Msg(4), Msg(5), Msg(6), Msg(7));
                Work_Area := GEM.AES.Window.Get(Win, Work_XYWH);
                Send_Redraw(Win, Work_Area);
            elsif Message_Type(Msg(0)) = Window_Fulled_Msg then
                declare
                    r   : aliased Rectangle;
                begin
                    if not fulled then
                        r := GEM.AES.Window.Get(Desktop_Handle, Work_XYWH);
                        GEM.AES.Window.Set(Win, Current_XYWH, r);
                        fulled := True;
                    else
                        r := GEM.AES.Window.Get(Win, Previous_XYWH);
                        GEM.AES.Window.Set(Win, Current_XYWH, r);
                        fulled := False;
                    end if;
                    Work_Area := GEM.AES.Window.Get(Win, Work_XYWH);
                    Send_Redraw(Win, Work_Area);
                end;
            elsif Message_Type(Msg(0)) = Window_Closed_Msg then
                Quit := True;
            end if;
            exit when Quit;
        end loop;
    end;

    GEM.AES.Window.Close(Win);
    GEM.AES.Window.Delete(Win);
    GEM.VDI.Close_Virtual_Screen_Workstation(Vdi_Handle);
    GEM.AES.Application.AExit;
end Lines;
