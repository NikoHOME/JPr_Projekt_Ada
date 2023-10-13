-- A skeleton of a program for an assignment in programming languages
-- The students should rename the tasks of producers, consumers, and the buffer
-- Then, they should change them so that they would fit their assignments
-- They should also complete the code with constructions that lack there
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Integer_Text_IO; 
with Ada.Numerics.Discrete_Random;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;


procedure Simulation is
   Number_Of_Products: constant Integer := 7;
   Number_Of_Assemblies: constant Integer := 5;
   Number_Of_Consumers: constant Integer := 4;
   subtype Product_Type is Integer range 1 .. Number_Of_Products;
   subtype Assembly_Type is Integer range 1 .. Number_Of_Assemblies;
   subtype Consumer_Type is Integer range 1 .. Number_Of_Consumers;
   
   subtype Reduced_Assembly_Type is Integer range 0 .. Number_Of_Assemblies - 1;
   -- used for generating an alternative assembly

   Product_Name: constant array (Product_Type) of Unbounded_String
     := (To_Unbounded_String("Diesel Locomotive"),
         To_Unbounded_String("Electric Locomotive"),
         To_Unbounded_String("Steam Locomotive"),
         To_Unbounded_String("Passenger Car"),
         To_Unbounded_String("Sleeping Car"),
         To_Unbounded_String("Boxcar"),
         To_Unbounded_String("Tank Car"));
   Assembly_Name: constant array (Assembly_Type) of Unbounded_String
     := (To_Unbounded_String("Train Playset 1 'Rookie's Ruckus'"),
         To_Unbounded_String("Train Playset 2 'Cargo Craze'"),
         To_Unbounded_String("Train Playset 3 'Freight Frenzy'"),
         To_Unbounded_String("Train Playset 4 'Passenger Passion'"),
         To_Unbounded_String("Train Playset 5 'Track Turmoil'"));                                       
   
   package Random_Assembly is new
     Ada.Numerics.Discrete_Random(Assembly_Type);
   type My_Str is new String(1 ..256);
   
   package Random_Reduced_Assembly is new
     Ada.Numerics.Discrete_Random(Reduced_Assembly_Type);

   -- Producer produces determined product
   task type Producer is
      -- Give the Producer an identity, i.e. the product type
      entry Start(Product: in Product_Type);
   end Producer;

   -- Consumer gets an arbitrary assembly of several products from the buffer
   task type Consumer is
      -- Give the Consumer an identity
      entry Start(Consumer_Number: in Consumer_Type);
   end Consumer;

   -- In the Buffer, products are assemblied into an assembly
   task type Buffer is
      -- Accept a product to the storage provided there is a room for it
      entry Take(Product: in Product_Type; Number: in Integer);
      -- Deliver an assembly provided there are enough products for it
      entry Deliver(Assembly: in Assembly_Type; Number: out Integer);
   end Buffer;

   P: array ( 1 .. Number_Of_Products ) of Producer;
   K: array ( 1 .. Number_Of_Consumers ) of Consumer;
   B: Buffer;

   task body Producer is
      subtype Production_Time_Range is Integer range 4 .. 8;
      package Random_Production is new
        Ada.Numerics.Discrete_Random(Production_Time_Range);
      G: Random_Production.Generator;	--  generator liczb losowych
      Product_Type_Number: Integer;
      Product_Number: Integer;
   begin
      accept Start(Product: in Product_Type) do
         Random_Production.Reset(G);	--  start random number generator
         Product_Number := 1;
         Product_Type_Number := Product;
      end Start;
      Put_Line("A workshop producing models of "
               & To_String(Product_Name(Product_Type_Number))
               & "s for us begins operations");
      loop
         delay Duration(Random_Production.Random(G)); --  symuluj produkcję
         Put_Line("A workshop has produced a model of a  "
                  & To_String(Product_Name(Product_Type_Number))
                  & " number "  & Integer'Image(Product_Number));
         -- Accept for storage
         B.Take(Product_Type_Number, Product_Number);
         Product_Number := Product_Number + 1;
      end loop;
   end Producer;

   task body Consumer is
      subtype Consumption_Time_Range is Integer range 12 .. 24;
      package Random_Consumption is new
        Ada.Numerics.Discrete_Random(Consumption_Time_Range);
      G: Random_Consumption.Generator;	--  random number generator (time)
      G2: Random_Assembly.Generator;	--  also (assemblies)
      G_Reduced : Random_Reduced_Assembly.Generator; -- also (switching assemblies)
      Consumer_Nb: Consumer_Type;
      Assembly_Number: Integer := 0;
      Assembly_Type: Integer;
      Alternate_Assembly_Type : Integer;
      Consumer_Name: constant array (1 .. Number_Of_Consumers)
        of Unbounded_String
          := (To_Unbounded_String("Customer Joe"),
              To_Unbounded_String("Customer Ben"),
              To_Unbounded_String("Customer Sam"),
              To_Unbounded_String("Customer Tom"));
      Patience_Of_A_Customer : constant Duration := 4.0;

      procedure Announce_Purchase
        (Consumer_Nb : Consumer_Type; 
         Assembly_Number : Integer; 
         Chosen_Assembly_Type : Integer) is
      begin
         if Assembly_Number /= 0 then
            Put_Line(To_String(Consumer_Name(Consumer_Nb)) & " has bought the "
                     & To_String(Assembly_Name(Chosen_Assembly_Type)) & " number "
                     & Integer'Image(Assembly_Number));
         else 
            Put_Line(To_String(Consumer_Name(Consumer_Nb)) & " couldn't buy the "
                     & To_String(Assembly_Name(Chosen_Assembly_Type))
                     & " and has therefore left our store");
         end if;
      end Announce_Purchase;

   begin
      accept Start(Consumer_Number: in Consumer_Type) do
         Random_Consumption.Reset(G);	--  ustaw generator
         Random_Assembly.Reset(G2);	--  też
         Consumer_Nb := Consumer_Number;
      end Start;
      Put_Line(To_String(Consumer_Name(Consumer_Nb))
               & ", model train aficionado, "
               & "becomes interested in the new model train store");
      loop
         delay Duration(Random_Consumption.Random(G)); --  simulate consumption
         Assembly_Type := Random_Assembly.Random(G2);
         Alternate_Assembly_Type
           := (Assembly_Type + Random_Reduced_Assembly.Random(G_Reduced)) mod Assembly_Type + 1;
         -- adding a number that /= 0 and smaller than the number of assemblies,
         -- take mod, add 1 to shift to the right range (1..n instead of 0..n-1)
         -- to ensure that a different assembly is picked

         Put_Line(To_String(Consumer_Name(Consumer_Nb)) & " came to buy a "
                  & To_String(Assembly_Name(Assembly_Type)));
         -- take an assembly for consumption
         select
            B.Deliver(Assembly_Type, Assembly_Number);
            Announce_Purchase(Consumer_Nb, Assembly_Number, Assembly_Type);
         or
            delay Patience_Of_A_Customer;
            Put_Line("After getting bored waiting in the queue "
                     & To_String(Consumer_Name(Consumer_Nb))
                     & " changed his mind and now wants a "
                     & To_String(Assembly_Name(Alternate_Assembly_Type)));
            B.Deliver(Alternate_Assembly_Type, Assembly_Number);         
            Announce_Purchase(Consumer_Nb, Assembly_Number, Alternate_Assembly_Type);
         end select;
      end loop;
   end Consumer;

   task body Buffer is
      Storage_Capacity: constant Integer := 60;
      type Storage_type is array (Product_Type) of Integer;
      Storage: Storage_type
        := (0, 0, 0, 0, 0, 0, 0);
      Assembly_Content: array(Assembly_Type, Product_Type) of Integer
        := ((1, 1, 1, 1, 1, 1, 1),
            (2, 0, 1, 0, 0, 3, 1),
            (1, 2, 0, 0, 0, 2, 1),
            (0, 2, 1, 4, 2, 0, 0),
            (1, 1, 2, 0, 1, 1, 0));
      Max_Assembly_Content: array(Product_Type) of Integer;
      Assembly_Number: array(Assembly_Type) of Integer
        := (1, 1, 1, 1, 1);
      In_Storage: Integer := 0;
      
      Max_Accepted_Products : array(Product_Type) of Integer;
      
      -- time it takes to give an assembly to a customer
      Customer_Handling_Time : constant Duration := 0.75; 

      -- time it takes to take a product from a producer
      Producer_Handling_Time : constant Duration := 0.75; 
      
      -- how long can we wait when there are no customers
      -- before we go to the storage room
      Patience_For_Customers : constant Duration := 3.0; 

      -- how long can we wait when there are no producers
      -- before we go to the cash register
      Patience_For_Producers : constant Duration := 1.0; 
                                                         
      -- how many products at most can we take before we go back to the cash register
      Max_Products_In_A_Row : constant Integer := 2 * Number_Of_Products;
      
      -- how many customers at most can we take serve we go back to the storage room
      Max_Customers_In_A_Row : constant Integer := 2 * Number_Of_Consumers;

      procedure Setup_Variables is
         Product_Occurrences : array(Product_Type) of Integer;
         Product_Occurrences_Sum : Integer := 0;
      begin
         for W in Product_Type loop
            Max_Assembly_Content(W) := 0;
            Product_Occurrences(W) := 0;
            for Z in Assembly_Type loop
               if Assembly_Content(Z, W) > Max_Assembly_Content(W) then
                  Max_Assembly_Content(W) := Assembly_Content(Z, W);
               end if;
               Product_Occurrences(W) 
                 := Product_Occurrences(W) + Assembly_Content(Z, W);
            end loop;
            Product_Occurrences_Sum 
              := Product_Occurrences_Sum + Product_Occurrences(W);
         end loop;
         
         for W in Product_Type loop
            Max_Accepted_Products(W)
              := Integer(Float'Ceiling(Float(Product_Occurrences(W)) / Float(Product_Occurrences_Sum) * Float(Storage_Capacity)));
            -- rounded up to ensure that the whole buffer can always be utilised
            
            if Max_Assembly_Content(W) > Max_Accepted_Products(W) then
               Max_Accepted_Products(W) := Max_Assembly_Content(W);
            end if; -- fail-safe for extremely unbalanced distributions
            
         end loop;
      end Setup_Variables;

      function Can_Accept(Product: Product_Type) return Boolean is
         Free: Integer;		--  free room in the storage
         -- how many products are for production of arbitrary assembly
         Lacking: array(Product_Type) of Integer;
         -- how much room is needed in storage to produce arbitrary assembly
         Lacking_room: Integer;
         MP: Boolean;			--  can accept
      begin
         if In_Storage >= Storage_Capacity then
            return False;
         end if;
         if Storage(Product) >= Max_Accepted_Products(Product) then
            return False;
         end if;
         -- There is free room in the storage
         Free := Storage_Capacity - In_Storage;
         MP := True;
         for W in Product_Type loop
            if Storage(W) < Max_Assembly_Content(W) then
               MP := False;
            end if;
         end loop;
         if MP then
            return True;    -- storage has products for arbitrary assembly
         end if;
         if Integer'Max(0, Max_Assembly_Content(Product) - Storage(Product)) > 0 then
            -- exactly this product lacks
            return True;
         end if;        
         Lacking_room := 1;			--  insert current product
         for W in Product_Type loop
            Lacking(W) := Integer'Max(0, Max_Assembly_Content(W) - Storage(W));
            Lacking_room := Lacking_room + Lacking(W);
         end loop;
         if Free >= Lacking_room then
            -- there is enough room in storage for arbitrary assembly
            return True;
         else
            -- no room for this product
            return False;
         end if;
      end Can_Accept;

      function Can_Deliver(Assembly: Assembly_Type) return Boolean is
      begin
         for W in Product_Type loop
            if Storage(W) < Assembly_Content(Assembly, W) then
               return False;
            end if;
         end loop;
         return True;
      end Can_Deliver;

      procedure Storage_Contents is
      begin
         Put_Line("Storage contents:");
         for W in Product_Type loop
            Put_Line(" -" & Integer'Image(Storage(W)) & " "
                     & To_String(Product_Name(W))
                     & (if Storage(W) /= 1 then "s" else "")); -- displaying plural forms
         end loop;
      end Storage_Contents;
      
      procedure Successful_Taking(Product: in Product_Type; Number: in Integer) is
      begin
         Put_Line("We have accepted a new " & To_String(Product_Name(Product))
                  & " number " & Integer'Image(Number)
                  & " from a workshop into out stock");
         Storage(Product) := Storage(Product) + 1;
         In_Storage := In_Storage + 1;
      end Successful_Taking;
      
      procedure Unsuccessful_Taking(Product: in Product_Type; Number: in Integer) is
      begin
         Put_Line("We already have enough "
                  & To_String(Product_Name(Product))
                  & "s in storage, so we had to reject the one numbered "
                  & Integer'Image(Number)
                  & ". They will give it to a different store");
      end Unsuccessful_Taking;

      procedure Successful_Delivery(Assembly: in Assembly_Type; Number: out Integer) is
      begin
         Put_Line("We sold the " & To_String(Assembly_Name(Assembly))
                  & " number " & Integer'Image(Assembly_Number(Assembly)));
         for W in Product_Type loop
            Storage(W) := Storage(W) - Assembly_Content(Assembly, W);
            In_Storage := In_Storage - Assembly_Content(Assembly, W);
         end loop;
         Number := Assembly_Number(Assembly);
         Assembly_Number(Assembly) := Assembly_Number(Assembly) + 1;
      end Successful_Delivery;

      procedure Unsuccessful_Delivery(Assembly: in Assembly_Type; Number: out Integer) is
      begin
         Put_Line("We don't have all the trains to sell the "
                  & To_String(Assembly_Name(Assembly)));
         Number := 0;
      end Unsuccessful_Delivery;
      
      Products_In_A_Row : Integer;
      Customers_In_A_Row : Integer;

   begin
      Put_Line("A new shop selling model trains opens!");
      Setup_Variables;
      loop
         Products_In_A_Row := 0;
         while Products_In_A_Row < Max_Products_In_A_Row loop
            select
               accept Take(Product: in Product_Type; Number: in Integer) do
                  if Can_Accept(Product) then
                     Successful_Taking(Product, Number);
                  else
                     Unsuccessful_Taking(Product, Number);
                  end if;
                  delay Producer_Handling_Time;
                  Products_In_A_Row := Products_In_A_Row + 1;
               end Take;
            or
               delay Patience_For_Producers;
               Put_Line("No producers for a while, let's go to the cash register");
               exit;
            end select;  
         end loop;
         if Products_In_A_Row >= Max_Products_In_A_Row then
            Put_Line("Enough producers, time to go to the cash register");
         end if;
         Storage_Contents;
                  
         Customers_In_A_Row := 0;
         while Customers_In_A_Row < Max_Customers_In_A_Row loop
            select
               accept Deliver(Assembly: in Assembly_Type; Number: out Integer) do
                  if Can_Deliver(Assembly) then
                     Successful_Delivery(Assembly, Number);
                  else
                     Unsuccessful_Delivery(Assembly, Number);
                  end if;
                  delay Customer_Handling_Time;
                  Customers_In_A_Row := Customers_In_A_Row + 1;
                  Storage_Contents;
               end Deliver;
            or
               delay Patience_For_Customers;
               Put_Line("No clients for a while, let's go to the storage room");
               exit;
            end select;
         end loop;
         if Customers_In_A_Row >= Max_Customers_In_A_Row then
            Put_Line("Enough customers, time to go to the storage room");
         end if;
      end loop;
   end Buffer;
   
begin
   for I in 1 .. Number_Of_Products loop
      P(I).Start(I);
   end loop;
   for J in 1 .. Number_Of_Consumers loop
      K(J).Start(J);
   end loop;
end Simulation;


